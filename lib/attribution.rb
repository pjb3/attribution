require "attribution/util"
require "attribution/version"
require "active_support/core_ext"

module Attribution
  BOOLEAN_TRUE_STRINGS = ['y','yes','t','true']

  def self.included(cls)
    cls.extend(ClassMethods)
  end

  def initialize(attrs={})
    attrs = JSON.parse(attrs) if attrs.is_a?(String)
    attrs.each do |k,v|
      setter = "#{k}="
      if respond_to?(setter)
        send(setter, v)
      else
        instance_variable_set("@#{k}", v)
      end
    end
  end

  # TODO: Use associations argument as a way to specify which associations should be included
  def attributes(*associations)
    self.class.attribute_names.inject({}) do |attrs, attr|
      attrs[attr] = send(attr)
      attrs
    end
  end

  module ClassMethods
    def cast(obj)
      case obj
      when Hash then new(obj)
      when self then obj
      else raise ArgumentError.new("can't convert #{obj.class} to #{name}")
      end
    end

    def attributes
      @attributes ||= []
    end

    def attribute_names
      @attribute_names ||= attributes.map{|a| a[:name] }
    end

    def add_attribute(name, type, metadata={})
      attr_reader name
      attributes << (metadata || {}).merge(:name => name.to_sym, :type => type.to_sym)
    end

    # Attribute macros
    def string(attr, metadata={})
      add_attribute(attr, :string, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : arg.to_s)
      end
    end

    def boolean(attr, metadata={})
      add_attribute(attr, :boolean, metadata)
      define_method("#{attr}=") do |arg|
        v = case arg
        when String then BOOLEAN_TRUE_STRINGS.include?(arg.downcase)
        when Numeric then arg == 1
        when nil then nil
        else !!arg
        end
        instance_variable_set("@#{attr}", v)
      end
      alias_method "#{attr}?", attr
    end

    def integer(attr, metadata={})
      add_attribute(attr, :integer, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : arg.to_i)
      end
    end

    def float(attr, metadata={})
      add_attribute(attr, :float, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : arg.to_f)
      end
    end

    def decimal(attr, metadata={})
      add_attribute(attr, :decimal, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : BigDecimal.new(arg.to_s))
      end
    end

    def date(attr, metadata={})
      add_attribute(attr, :date, metadata)
      define_method("#{attr}=") do |arg|
        v = case arg
        when Date then arg
        when Time, DateTime then arg.to_date
        when String then Date.parse(arg)
        when Hash
          args = Util.extract_values(arg, :year, :month, :day)
          args.present? ? Date.new(*args.map(&:to_i)) : nil
        when nil then nil
        else raise ArgumentError.new("can't convert #{arg.class} to Date")
        end
        instance_variable_set("@#{attr}", v)
      end
    end

    def time(attr, metadata={})
      add_attribute(attr, :time, metadata)
      define_method("#{attr}=") do |arg|
        v = case arg
        when Date, DateTime then arg.to_time
        when Time then arg
        when String then Time.parse(arg)
        when Hash
          args = Util.extract_values(arg, :year, :month, :day, :hour, :min, :sec, :utc_offset)
          args.present? ? Time.new(*args.map(&:to_i)) : nil
        when nil then nil
        else raise ArgumentError.new("can't convert #{arg.class} to Time")
        end
        instance_variable_set("@#{attr}", v)
      end
    end

    def time_zone(attr, metadata={})
      add_attribute(attr, :time_zone, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : ActiveSupport::TimeZone[arg.to_s])
      end
    end

    # Association macros
    def belongs_to(association_name, metadata={})
      # foo_id
      id_getter = "#{association_name}_id".to_sym
      add_attribute(id_getter, :integer, metadata)
      define_method(id_getter) do
        ivar = "@#{id_getter}"
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          if obj = send(association_name)
            instance_variable_set(ivar, obj.id)
          else
            instance_variable_set(ivar, nil)
          end
        end
      end

      # foo_id=
      define_method("#{id_getter}=") do |arg|
        instance_variable_set("@#{id_getter}", arg.to_i)
      end

      # foo
      define_method(association_name) do
        if instance_variable_defined?("@#{association_name}")
          instance_variable_get("@#{association_name}")
        elsif id = instance_variable_get("@#{association_name}_id")
          # TODO: Support a more generic version of lazy-loading
          begin
            association_class = association_name.to_s.classify.constantize
          rescue NameError => ex
            raise ArgumentError.new("Association #{association_name} in #{self.class} is invalid because #{association_name.to_s.classify} does not exist")
          end

          if association_class.respond_to?(:find)
            instance_variable_set("@#{association_name}", association_class.find(id))
          end
        else
          instance_variable_set("@#{association_name}", nil)
        end
      end

      # foo=
      define_method("#{association_name}=") do |arg|
        begin
          association_class = association_name.to_s.classify.constantize
        rescue NameError => ex
          raise ArgumentError.new("Association #{association_name} in #{self.class} is invalid because #{association_name.to_s.classify} does not exist")
        end

        if instance_variable_defined?("@#{association_name}_id")
          remove_instance_variable("@#{association_name}_id")
        end
        instance_variable_set("@#{association_name}", association_class.cast(arg))
      end
    end

    def has_many(association_name)
      # foos
      define_method(association_name) do
        ivar = "@#{association_name}"
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          # TODO: Support a more generic version of lazy-loading
          begin
            association_class = association_name.to_s.singularize.classify.constantize
          rescue NameError => ex
            raise ArgumentError.new("Association #{association_name} in #{self.class} is invalid because #{association_name.to_s.classify} does not exist")
          end

          if association_class.respond_to?(:all)
            instance_variable_set(ivar, Array(association_class.all("#{self.class.name.underscore}_id" => id)))
          end
        end
      end

      # foos=
      define_method("#{association_name}=") do |arg|
        # TODO: put this in method
        begin
          association_class = association_name.to_s.singularize.classify.constantize
        rescue NameError => ex
          raise ArgumentError.new("Association #{association_name} in #{self.class} is invalid because #{association_name.to_s.classify} does not exist")
        end

        objs = Array(arg).map do |obj|
          o = association_class.cast(obj)
          o.send("#{self.class.name.underscore}=", self)
          o.send("#{self.class.name.underscore}_id=", id)
          o
        end
        instance_variable_set("@#{association_name}", objs)
      end
    end
  end
end
