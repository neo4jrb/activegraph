require 'active_support/core_ext/object/blank'

module Neo4j::Shared
  module Typecasting
    # Typecasts an Object to true or false
    #
    # @example Usage
    #   BooleanTypecaster.new.call(1) #=> true
    #
    # @since 0.5.0
    class BooleanTypecaster
      # Values which force a false result for typecasting
      #
      # These values are based on the
      # {YAML language}[http://yaml.org/type/bool.html].
      #
      # @since 0.5.0
      FALSE_VALUES = %w(n N no No NO false False FALSE off Off OFF f F)

      # Typecasts an object to true or false
      #
      # Similar to ActiveRecord, when the attribute is a zero value or
      # is a string that represents false, typecasting returns false.
      # Otherwise typecasting just checks the presence of a value.
      #
      # @example Typecast a Fixnum
      #   typecaster.call(1) #=> true
      #
      # @param [Object] value The object to typecast
      #
      # @return [true, false] The result of typecasting
      #
      # @since 0.5.0
      def call(value)
        case value
        when Numeric, /^\-?[0-9]/ then !value.to_f.zero?
        when *FALSE_VALUES then false
        else value.present?
        end
      end
    end
  end
end
