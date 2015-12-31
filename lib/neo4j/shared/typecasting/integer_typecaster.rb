# rubocop:disable Lint/HandleExceptions
module Neo4j::Shared
  module Typecasting
    # Typecasts an Object to an Integer
    #
    # @example Usage
    #   IntegerTypecaster.new.call("1") #=> 1
    #
    # @since 0.5.0
  class IntegerTypecaster
      # Typecasts an object to an Integer
      #
      # Attempts to convert using #to_i. Handles FloatDomainError if the
      # object is INFINITY or NAN.
      #
      # @example Typecast a String
      #   typecaster.call("1") #=> 1
      #
      # @param [Object, #to_i] value The object to typecast
      #
      # @return [Integer, nil] The result of typecasting
      #
      # @since 0.5.0
      def call(value)
        value.to_i if value.respond_to? :to_i
      rescue FloatDomainError
      end
    end
  end
end
# rubocop:enable Lint/HandleExceptions
