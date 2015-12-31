require 'neo4j/shared/typecasting/big_decimal_typecaster'
require 'neo4j/shared/typecasting/boolean'
require 'neo4j/shared/typecasting/boolean_typecaster'
require 'neo4j/shared/typecasting/date_time_typecaster'
require 'neo4j/shared/typecasting/date_typecaster'
require 'neo4j/shared/typecasting/float_typecaster'
require 'neo4j/shared/typecasting/integer_typecaster'
require 'neo4j/shared/typecasting/object_typecaster'
require 'neo4j/shared/typecasting/string_typecaster'
require 'neo4j/shared/typecasting/unknown_typecaster_error'

module Neo4j::Shared
  # Typecasting provides methods to typecast a value to a different type
  #
  # The following types are supported for typecasting:
  # * BigDecimal
  # * Boolean
  # * Date
  # * DateTime
  # * Float
  # * Integer
  # * Object
  # * String
  #
  # @since 0.5.0
  module Typecasting
    # @private
    TYPECASTER_MAP = {
      BigDecimal => BigDecimalTypecaster,
      Boolean    => BooleanTypecaster,
      Date       => DateTypecaster,
      DateTime   => DateTimeTypecaster,
      Float      => FloatTypecaster,
      Integer    => IntegerTypecaster,
      Object     => ObjectTypecaster,
      String     => StringTypecaster
    }.freeze

    # Typecasts a value using a Class
    #
    # @param [#call] typecaster The typecaster to use for typecasting
    # @param [Object] value The value to be typecasted
    #
    # @return [Object, nil] The typecasted value or nil if it cannot be
    #   typecasted
    #
    # @since 0.5.0
    def typecast_attribute(typecaster, value)
      fail ArgumentError, 'a typecaster must be given' unless typecaster.respond_to?(:call)
      return value if value.nil?
      typecaster.call(value)
    end

    # Resolve a Class to a typecaster
    #
    # @param [Class] type The type to cast to
    #
    # @return [#call, nil] The typecaster to use
    #
    # @since 0.6.0
    def typecaster_for(type)
      typecaster = TYPECASTER_MAP[type]
      typecaster.new if typecaster
    end
  end
end
