require 'active_support/core_ext/string/conversions'
require 'active_support/time'

module Neo4j::Shared
  module Typecasting
    # Typecasts an Object to a DateTime
    #
    # @example Usage
    #   typecaster = DateTimeTypecaster.new
    #   typecaster.call("2012-01-01") #=> Sun, 01 Jan 2012 00:00:00 +0000
    #
    # @since 0.5.0
    class DateTimeTypecaster
      # Typecasts an object to a DateTime
      #
      # Attempts to convert using #to_datetime.
      #
      # @example Typecast a String
      #   typecaster.call("2012-01-01") #=> Sun, 01 Jan 2012 00:00:00 +0000
      #
      # @param [Object, #to_datetime] value The object to typecast
      #
      # @return [DateTime, nil] The result of typecasting
      #
      # @since 0.5.0
      def call(value)
        value.to_datetime if value.respond_to? :to_datetime
      end
    end
  end
end
