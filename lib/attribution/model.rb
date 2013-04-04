require 'attribution/id'
require 'attribution/timestamps'
require 'attribution/validations'

module Attribution
  module Model
    def self.included(cls)
      cls.class_eval do
        include Attribution
        include ID
        include Timestamps
        include Validations
      end
    end
  end
end
