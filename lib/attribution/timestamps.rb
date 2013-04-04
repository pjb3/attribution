module Attribution
  module Timestamps
    def self.included(cls)
      cls.class_eval do
        time :created_at
        time :updated_at
      end
    end
  end
end
