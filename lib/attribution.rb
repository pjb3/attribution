require 'active_support/core_ext'
require 'attribution/util'
require 'attribution/version'

module Attribution
  BOOLEAN_TRUE_STRINGS = ['y','yes','t','true']

  def self.included(cls)
    cls.extend(ClassMethods)
  end

  def initialize(attributes={})
    self.class.attribute_names.each do |attr|
      instance_variable_set("@#{attr}", nil)
    end
    self.attributes = attributes
  end

  # @return [Hash] the attributes of this instance and their values
  def attributes(*associations)
    self.class.attribute_names.inject({}) do |attrs, attr|
      attrs[attr] = send(attr)
      attrs
    end
  end
  alias_method :to_h, :attributes

  # @param [String, Hash] attributes The attributes and their values
  def attributes=(attributes)
    attributes = case attributes
    when String then JSON.parse(attributes)
    when Hash then attributes
    else {}
    end.with_indifferent_access

    attributes.each do |k,v|
      setter = "#{k}="
      if respond_to?(setter)
        send(setter, v)
      end
    end
  end

  module ClassMethods

    # @param [Hash, Attribution] obj The Hash or Object to convert to
    #   an instance of this class
    # @return [Attribution] An instance of this class
    def cast(obj)
      case obj
      when Hash then new(obj)
      when self then obj
      else raise ArgumentError.new("can't convert #{obj.class} to #{name}")
      end
    end

    # @return [Hash{Symbol => Object}] Each attribute name, type and
    #   any related metadata in the order in which they were defined
    def attributes
      @attributes ||= if superclass && superclass.respond_to?(:attributes)
        superclass.attributes.dup
      else
        []
      end
    end

    # @return [Array<Symbol>] The names of the attributes
    #   in the order in which they were defined
    def attribute_names
      @attribute_names ||= attributes.map{|a| a[:name] }
    end

    # Attribute macros

    # Defines an attribute
    #
    # @param [String] name The name of the attribute
    # @param [Symbol] type The type of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def add_attribute(name, type, metadata={})
      attr_reader name
      attributes << (metadata || {}).merge(:name => name.to_sym, :type => type.to_sym)
    end

    # Defines a string attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def string(attr, metadata={})
      add_attribute(attr, :string, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : arg.to_s)
      end
    end

    # Defines a boolean attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
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

    # Defines a integer attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def integer(attr, metadata={})
      add_attribute(attr, :integer, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : arg.to_i)
      end
    end

    # Defines a float attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def float(attr, metadata={})
      add_attribute(attr, :float, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : arg.to_f)
      end
    end

    # Defines a decimal attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def decimal(attr, metadata={})
      add_attribute(attr, :decimal, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : BigDecimal.new(arg.to_s))
      end
    end

    # Defines a date attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
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

    # Defines a time attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
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

    # Defines a time zone attribute, based on ActiveSupport::TimeZone
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def time_zone(attr, metadata={})
      add_attribute(attr, :time_zone, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg.nil? ? nil : ActiveSupport::TimeZone[arg.to_s])
      end
    end

    # Defines an array attribute
    #
    # @param [Symbol] attr The name of the attribute
    # @param [Hash{Symbol => Object}] metadata The metadata for the attribute
    def array(attr, metadata={})
      add_attribute(attr, :array, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", Array(arg))
      end
    end

    # Defines a hash attribute. This is named hash_attr instead of hash
    # to avoid a conflict with Object#hash
    #
    # @params [Symbol] attr The name of the attribute
    # @params [Hash{Symbol => Object}] metadata The metadata for the attribute
    def hash_attr(attr, metadata={})
      add_attribute(attr, :hash, metadata)
      define_method("#{attr}=") do |arg|
        instance_variable_set("@#{attr}", arg || {})
      end
    end

    # Associations

    # @return [Array<Hash>] The associations for this class
    def associations
      @associations ||= if superclass && superclass.respond_to?(:associations)
        superclass.associations.dup
      else
        []
      end
    end

    # Defines an association
    #
    # @param [String] name The name of the association
    # @param [Symbol] type The type of the association
    # @param [Hash{Symbol => Object}] metadata The metadata for the association
    def add_association(name, type, metadata={})
      associations << (metadata || {}).merge(:name => name.to_sym, :type => type.to_sym)
    end

    # @param [Boolean] autoload_associations Enable/Disable autoloading of
    #   associations for this class and all subclasses.
    def autoload_associations(autoload_associations)
      @autoload_associations = autoload_associations
    end

    # @return [Boolean] autoload_associations Whether or not this will
    #   autoload associations.
    def autoload_associations?
      if defined? @autoload_associations
        @autoload_associations
      elsif superclass.respond_to?(:autoload_associations?)
        superclass.autoload_associations?
      else
        true
      end
    end

    # Association macros
    #
    # Defines an association that is a reference to another Attribution class.
    #
    # @param [Symbol] association_name The name of the association
    # @param [Hash] metadata Extra information about the association.
    # @option metadata [String] :class_name Class of the association,
    #   defaults to a class name based on the association name
    def belongs_to(association_name, metadata={})
      # foo_id
      id_getter = "#{association_name}_id".to_sym
      add_attribute(id_getter, :integer, metadata)
      add_association association_name, :belongs_to, metadata
      association_class_name = metadata.try(:fetch, :class_name, [name.split('::')[0..-2].join('::'), association_name.to_s.classify].reject(&:blank?).join('::'))

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
          association_class = association_class_name.constantize

          if self.class.autoload_associations? && association_class.respond_to?(:find)
            instance_variable_set("@#{association_name}", association_class.find(id))
          end
        else
          instance_variable_set("@#{association_name}", nil)
        end
      end

      # foo=
      define_method("#{association_name}=") do |arg|
        association_class = association_class_name.constantize

        if instance_variable_defined?("@#{association_name}_id")
          remove_instance_variable("@#{association_name}_id")
        end
        instance_variable_set("@#{association_name}", association_class.cast(arg))
      end
    end

    # Defines an association that is a reference to an Array of another Attribution class.
    #
    # @param [Symbol] association_name The name of the association
    # @param [Hash] metadata Extra information about the association.
    # @option metadata [String] :class_name Class of the association,
    #   defaults to a class name based on the association name
    def has_many(association_name, metadata={})

      add_association association_name, :has_many, metadata

      association_class_name = metadata.try(:fetch, :class_name, [name.split('::')[0..-2].join('::'), association_name.to_s.singularize.classify].reject(&:blank?).join('::'))

      # foos
      define_method(association_name) do |*query|
        association_class = association_class_name.constantize

        # TODO: Support a more generic version of lazy-loading
        if query.empty? # Ex: Books.all, so we want to cache it.
          ivar = "@#{association_name}"
          if instance_variable_defined?(ivar)
            instance_variable_get(ivar)
          elsif self.class.autoload_associations? && association_class.respond_to?(:all)
            instance_variable_set(ivar, Array(association_class.all("#{self.class.name.underscore}_id" => id)))
          end
        else # Ex: Book.all(:name => "The..."), so we do not want to cache it
          if self.class.autoload_associations? && association_class.respond_to?(:all)
            Array(association_class.all({"#{self.class.name.demodulize.underscore}_id" => id}.merge(query.first)))
          end
        end
      end

      # foos=
      define_method("#{association_name}=") do |arg|
        association_class = association_class_name.constantize

        attr_name = self.class.name.demodulize.underscore
        objs = (arg.is_a?(Hash) ? arg.values : Array(arg)).map do |obj|
          o = association_class.cast(obj)

          if o.respond_to?("#{attr_name}=")
            o.send("#{attr_name}=", self)
          end

          if o.respond_to?("#{attr_name}_id=") && respond_to?(:id)
            o.send("#{attr_name}_id=", id)
          end

          o
        end
        instance_variable_set("@#{association_name}", objs)
      end
    end
  end
end
