module Neo4j::Shared
  module Typecasting
    # Typecasts an Object to a Float
    #
    # @example Usage
    #   FloatTypecaster.new.call(1) #=> 1.0
    #
    # @since 0.5.0
    class FloatTypecaster
      # Typecasts an object to a Float
      #
      # Attempts to convert using #to_f.
      #
      # @example Typecast a Fixnum
      #   typecaster.call(1) #=> 1.0
      #
      # @param [Object, #to_f] value The object to typecast
      #
      # @return [Float, nil] The result of typecasting
      #
      # @since 0.5.0
      def call(value)
        value.to_f if value.respond_to? :to_f
      end
    end
  end
end
