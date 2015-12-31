module Neo4j::Shared
  module Typecasting
    # Typecasts an Object to a String
    #
    # @example Usage
    #   StringTypecaster.new.call(1) #=> "1"
    #
    # @since 0.5.0
    class StringTypecaster
      # Typecasts an object to a String
      #
      # Attempts to convert using #to_s.
      #
      # @example Typecast a Fixnum
      #   typecaster.call(1) #=> "1"
      #
      # @param [Object, #to_s] value The object to typecast
      #
      # @return [String, nil] The result of typecasting
      #
      # @since 0.5.0
      def call(value)
        value.to_s if value.respond_to? :to_s
      end
    end
  end
end
