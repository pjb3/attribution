module Attribution
  module Util
    # Returns an array of the values that match each key,
    # up until the point at which it finds a blank value.
    #
    # @params hash Hash The hash containing values
    # @params keys [Object] The keys to look up in the Hash
    # @return [Object] The values
    # @example
    #   extract_values({ a: 1, b: 2, c: nil, d: 4}, :a, :b, :c :d) # => [1, 2]
    def self.extract_values(hash, *keys)
      values = []
      keys.each do |key|
        value = hash[key]
        if value.present?
          values << value
        else
          break
        end
      end
      values
    end
  end
end
