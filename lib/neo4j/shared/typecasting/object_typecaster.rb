module Neo4j::Shared
  module Typecasting
    # A "null" typecaster to provide uniformity
    #
    # @example Usage
    #   ObjectTypecaster.new.call("") #=> ""
    #
    # @since 0.5.0
    class ObjectTypecaster
      # Returns the original value unmodified
      #
      # @example Typecast an Object
      #   typecaster.call(1) #=> 1
      #
      # @param [Object] value The object to typecast
      #
      # @return [Object] Whatever you passed in
      #
      # @since 0.5.0
      def call(value)
        value
      end
    end
  end
end
