require 'active_support/core_ext/string/conversions'
require 'active_support/time'

# rubocop:disable Lint/HandleExceptions
module Neo4j::Shared
  module Typecasting
    # Typecasts an Object to a Date
    #
    # @example Usage
    #   DateTypecaster.new.call("2012-01-01") #=> Sun, 01 Jan 2012
    class DateTypecaster
      # Typecasts an object to a Date
      #
      # Attempts to convert using #to_date.
      #
      # @example Typecast a String
      #   typecaster.call("2012-01-01") #=> Sun, 01 Jan 2012
      #
      # @param [Object, #to_date] value The object to typecast
      #
      # @return [Date, nil] The result of typecasting
      def call(value)
        value.to_date if value.respond_to? :to_date
      rescue NoMethodError, ArgumentError
      end
    end
  end
end
# rubocop:enable Lint/HandleExceptions
