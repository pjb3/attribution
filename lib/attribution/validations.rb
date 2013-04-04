require 'active_model'

module Attribution
  module Validations

    def self.included(cls)
      cls.class_eval do
        extend ClassMethods
        include ActiveModel::Validations
      end
    end

    module ClassMethods

      VALIDATIONS = [
        [:presence, :required],
        [:presence],
        [:uniqueness, :unique],
        [:uniqueness],
        [:format],
        [:length],
        [:inclusion],
        [:numericality, :number],
        [:numericality]
      ]

      def add_attribute(name, type, metadata={})
        super
        VALIDATIONS.each do |validation_name, validation_alias|
          validation_alias ||= validation_name
          if metadata[validation_alias] == true
            validates name, validation_name => true
          elsif metadata[validation_alias]
            validates name, validation_name => metadata[validation_alias]
          end
        end
      end

    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def errors=(errs)
      if errs
        errs.each do |attr, e|
          errors.add attr, e
        end
      end
    end
  end
end
