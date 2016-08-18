require 'date'
require 'bigdecimal'
require 'bigdecimal/util'
require 'active_support/core_ext/big_decimal/conversions'
require 'active_support/core_ext/string/conversions'

module Neo4j::Shared
  class Boolean; end

  module TypeConverters
    CONVERTERS = {}

    class Boolean; end

    class BaseConverter
      class << self
        def converted?(value)
          value.is_a?(db_type)
        end
      end

      def supports_array?
        false
      end
    end

    class IntegerConverter < BaseConverter
      class << self
        def convert_type
          Integer
        end

        def db_type
          Integer
        end

        def to_db(value)
          value.to_i
        end

        alias_method :to_ruby, :to_db
      end
    end

    class FloatConverter < BaseConverter
      class << self
        def convert_type
          Float
        end

        def db_type
          Float
        end

        def to_db(value)
          value.to_f
        end
        alias_method :to_ruby, :to_db
      end
    end

    class BigDecimalConverter < BaseConverter
      class << self
        def convert_type
          BigDecimal
        end

        def db_type
          BigDecimal
        end

        def to_db(value)
          case value
          when Rational
            value.to_f.to_d
          when respond_to?(:to_d)
            value.to_d
          else
            BigDecimal.new(value.to_s)
          end
        end
        alias_method :to_ruby, :to_db
      end
    end

    class StringConverter < BaseConverter
      class << self
        def convert_type
          String
        end

        def db_type
          String
        end

        def to_db(value)
          value.to_s
        end
        alias_method :to_ruby, :to_db
      end
    end

    class BooleanConverter < BaseConverter
      FALSE_VALUES = %w(n N no No NO false False FALSE off Off OFF f F)

      class << self
        def converted?(value)
          converted_values.include?(value)
        end

        def converted_values
          [true, false]
        end

        def db_type
          Neo4j::Shared::Boolean
        end

        alias_method :convert_type, :db_type

        def to_db(value)
          return false if FALSE_VALUES.include?(value)
          case value
          when TrueClass, FalseClass
            value
          when Numeric, /^\-?[0-9]/
            !value.to_f.zero?
          else
            value.present?
          end
        end

        alias_method :to_ruby, :to_db
      end
    end

    # Converts Date objects to Java long types. Must be timezone UTC.
    class DateConverter < BaseConverter
      class << self
        def convert_type
          Date
        end

        def db_type
          Integer
        end

        def to_db(value)
          Time.utc(value.year, value.month, value.day).to_i
        end

        def to_ruby(value)
          value.respond_to?(:to_date) ? value.to_date : Time.at(value).utc.to_date
        end
      end
    end

    # Converts DateTime objects to and from Java long types. Must be timezone UTC.
    class DateTimeConverter < BaseConverter
      class << self
        def convert_type
          DateTime
        end

        def db_type
          Integer
        end

        # Converts the given DateTime (UTC) value to an Integer.
        # DateTime values are automatically converted to UTC.
        def to_db(value)
          value = value.new_offset(0) if value.respond_to?(:new_offset)

          args = [value.year, value.month, value.day]
          args += (value.class == Date ? [0, 0, 0] : [value.hour, value.min, value.sec])

          Time.utc(*args).to_i
        end

        def to_ruby(value)
          return value if value.is_a?(DateTime)
          t = case value
              when Time
                return value.to_datetime.utc
              when Integer
                Time.at(value).utc
              when String
                return value.to_datetime
              else
                fail ArgumentError, "Invalid value type for DateType property: #{value.inspect}"
              end

          DateTime.civil(t.year, t.month, t.day, t.hour, t.min, t.sec)
        end
      end
    end

    class TimeConverter < BaseConverter
      class << self
        def convert_type
          Time
        end

        def db_type
          Integer
        end

        # Converts the given DateTime (UTC) value to an Integer.
        # Only utc times are supported !
        def to_db(value)
          if value.class == Date
            Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
          else
            value.utc.to_i
          end
        end

        def to_ruby(value)
          Time.at(value).utc
        end
      end
    end

    # Converts hash to/from YAML
    class YAMLConverter < BaseConverter
      class << self
        def convert_type
          Hash
        end

        def db_type
          String
        end

        def to_db(value)
          Psych.dump(value)
        end

        def to_ruby(value)
          Psych.load(value)
        end
      end
    end

    # Converts hash to/from JSON
    class JSONConverter < BaseConverter
      class << self
        def convert_type
          JSON
        end

        def db_type
          String
        end

        def to_db(value)
          value.to_json
        end

        def to_ruby(value)
          JSON.parse(value, quirks_mode: true)
        end
      end
    end

    class EnumConverter
      def initialize(enum_keys, options)
        @enum_keys = enum_keys
        @options = options
      end

      def converted?(value)
        value.is_a?(db_type)
      end

      def supports_array?
        true
      end

      def db_type
        Integer
      end

      def convert_type
        Symbol
      end

      def to_ruby(value)
        @enum_keys.key(value) unless value.nil?
      end

      alias_method :call, :to_ruby

      def to_db(value)
        if value.is_a?(Array)
          value.map(&method(:to_db))
        else
          @enum_keys[value.to_s.to_sym] || 0
        end
      end
    end

    class ObjectConverter < BaseConverter
      class << self
        def convert_type
          Object
        end

        def to_ruby(value)
          value
        end
      end
    end


    # Modifies a hash's values to be of types acceptable to Neo4j or matching what the user defined using `type` in property definitions.
    # @param [Neo4j::Shared::Property] obj A node or rel that mixes in the Property module
    # @param [Symbol] medium Indicates the type of conversion to perform.
    # @param [Hash] properties A hash of symbol-keyed properties for conversion.
    def convert_properties_to(obj, medium, properties)
      direction = medium == :ruby ? :to_ruby : :to_db
      properties.each_pair do |key, value|
        next if skip_conversion?(obj, key, value)
        properties[key] = convert_property(key, value, direction)
      end
    end

    # Converts a single property from its current format to its db- or Ruby-expected output type.
    # @param [Symbol] key A property declared on the model
    # @param value The value intended for conversion
    # @param [Symbol] direction Either :to_ruby or :to_db, indicates the type of conversion to perform
    def convert_property(key, value, direction)
      converted_property(primitive_type(key.to_sym), value, direction)
    end

    def supports_array?(key)
      type = primitive_type(key.to_sym)
      type.respond_to?(:supports_array?) && type.supports_array?
    end

    def typecaster_for(value)
      Neo4j::Shared::TypeConverters.typecaster_for(value)
    end

    def typecast_attribute(typecaster, value)
      Neo4j::Shared::TypeConverters.typecast_attribute(typecaster, value)
    end

    private

    def converted_property(type, value, direction)
      return nil if value.nil?
      type.respond_to?(:db_type) || TypeConverters::CONVERTERS[type] ? TypeConverters.to_other(direction, value, type) : value
    end

    # If the attribute is to be typecast using a custom converter, which converter should it use? If no, returns the type to find a native serializer.
    def primitive_type(attr)
      case
      when self.serialized_properties_keys.include?(attr)
        serialized_properties[attr]
      when self.magic_typecast_properties_keys.include?(attr)
        self.magic_typecast_properties[attr]
      else
        self.fetch_upstream_primitive(attr)
      end
    end

    # Returns true if the property isn't defined in the model or if it is nil
    def skip_conversion?(obj, attr, value)
      !obj.class.attributes[attr] || value.nil?
    end

    class << self
      def included(_)
        Neo4j::Shared::TypeConverters.constants.each do |constant_name|
          constant = Neo4j::Shared::TypeConverters.const_get(constant_name)
          register_converter(constant) if constant.respond_to?(:convert_type)
        end
      end

      def typecast_attribute(typecaster, value)
        fail ArgumentError, "A typecaster must be given, #{typecaster} is invalid" unless typecaster.respond_to?(:to_ruby)
        return value if value.nil?
        typecaster.to_ruby(value)
      end

      def typecaster_for(primitive_type)
        return nil if primitive_type.nil?
        CONVERTERS[primitive_type]
      end

      # @param [Symbol] direction either :to_ruby or :to_other
      def to_other(direction, value, type)
        fail "Unknown direction given: #{direction}" unless direction == :to_ruby || direction == :to_db
        found_converter = converter_for(type)
        return value unless found_converter
        return value if direction == :to_db && formatted_for_db?(found_converter, value)
        found_converter.send(direction, value)
      end

      def converter_for(type)
        type.respond_to?(:db_type) ? type : CONVERTERS[type]
      end

      # Attempts to determine whether conversion should be skipped because the object is already of the anticipated output type.
      # @param [#convert_type] found_converter An object that responds to #convert_type, hinting that it is a type converter.
      # @param value The value for conversion.
      def formatted_for_db?(found_converter, value)
        return false unless found_converter.respond_to?(:db_type)
        found_converter.respond_to?(:converted) ? found_converter.converted?(value) : value.is_a?(found_converter.db_type)
      end

      def register_converter(converter)
        CONVERTERS[converter.convert_type] = converter
      end
    end
  end
end
