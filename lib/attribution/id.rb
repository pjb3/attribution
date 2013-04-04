module Attribution
  module ID
    def self.included(cls)
      cls.class_eval do
        integer :id

        alias_method :to_param, :id
      end
    end

    def ==(o)
      o.class == self.class && o.id == id
    end
    alias_method :eql?, :==

    def hash
      id.hash
    end
  end
end
