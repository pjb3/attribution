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
      send("#{k}=", v)
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

    # Attribute macros
    def string(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.to_s)
      end
    end

    def boolean(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        v = case arg
        when String then BOOLEAN_TRUE_STRINGS.include?(arg.downcase)
        when Numeric then arg == 1
        else !!arg
        end
        instance_variable_set("@#{attr}", v)
      end
      alias_method "#{attr}?", attr
    end

    def integer(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.to_i)
      end
    end

    def float(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.to_f)
      end
    end

    def decimal(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", BigDecimal.new(arg.to_s))
      end
    end

    def date(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        v = case arg
        when Date then arg
        when Time, DateTime then arg.to_date
        when String then Date.parse(arg)
        else raise ArgumentError.new("can't convert #{arg.class} to Date")
        end
        instance_variable_set("@#{attr}", v)
      end
    end

    def time(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        v = case arg
        when Date, DateTime then arg.to_time
        when Time then arg
        when String then Time.parse(arg)
        else raise ArgumentError.new("can't convert #{arg.class} to Time")
        end
        instance_variable_set("@#{attr}", v)
      end
    end

    def time_zone(attr)
      attr_reader(attr)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", ActiveSupport::TimeZone[arg.to_s])
      end
    end

    # Association macros
    def belongs_to(association_name)
      # foo_id
      define_method("#{association_name}_id") do
        ivar = "@#{association_name}_id"
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
      define_method("#{association_name}_id=") do |arg|
        instance_variable_set("@#{association_name}_id", arg.to_i)
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
