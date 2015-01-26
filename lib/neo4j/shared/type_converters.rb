module Neo4j::Shared
  module TypeConverters
    # Converts Date objects to Java long types. Must be timezone UTC.
    class DateConverter
      class << self
        def convert_type
          Date
        end

        def to_db(value)
          Time.utc(value.year, value.month, value.day).to_i
        end

        def to_ruby(value)
          Time.at(value).utc.to_date
        end
      end
    end

    # Converts DateTime objects to and from Java long types. Must be timezone UTC.
    class DateTimeConverter
      class << self
        def convert_type
          DateTime
        end

        # Converts the given DateTime (UTC) value to an Integer.
        # DateTime values are automatically converted to UTC.
        def to_db(value)
          value = value.new_offset(0) if value.respond_to?(:new_offset)
          if value.class == Date
            Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
          else
            Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec).to_i
          end
        end

        DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S %z'
        def to_ruby(value)
          t = case value
              when Integer
                Time.at(value).utc
              when String
                DateTime.strptime(value, DATETIME_FORMAT)
              else
                fail ArgumentError, "Invalid value type for DateType property: #{value.inspect}"
              end

          DateTime.civil(t.year, t.month, t.day, t.hour, t.min, t.sec)
        end
      end
    end

    class TimeConverter
      class << self
        def convert_type
          Time
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
    class YAMLConverter
      class << self
        def convert_type
          Hash
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
    class JSONConverter
      class << self
        def convert_type
          JSON
        end

        def to_db(value)
          value.to_json
        end

        def to_ruby(value)
          JSON.parse(value, quirks_mode: true)
        end
      end
    end

    def convert_properties_to(medium, properties)
      converter = medium == :ruby ? :to_ruby : :to_db

      properties.each_with_object({}) do |(attr, value), new_attributes|
        next new_attributes if skip_conversion?(attr, value)
        primitive = primitive_type(attr.to_sym)
        new_attributes[attr] = converted_property(primitive, value, converter)
      end
    end

    private

    def converted_property(type, value, converter)
      TypeConverters.converters[type].nil? ? value : TypeConverters.send(converter, value, type)
    end

    # If the attribute is to be typecast using a custom converter, which converter should it use? If no, returns the type to find a native serializer.
    def primitive_type(attr)
      case
      when serialized_properties.key?(attr)
        serialized_properties[attr]
      when magic_typecast_properties.key?(attr)
        self.class.magic_typecast_properties[attr]
      else
        self.class._attribute_type(attr)
      end
    end

    # Moves on if the property is either undeclared (UUID or just not included in the model) or nil and unchanged
    def skip_conversion?(attr, value)
      !self.class.attributes[attr] || (value.nil? && !changed_attributes.key?(attr))
    end

    class << self
      def typecaster_for(primitive_type)
        converters.key?(primitive_type) ? converters[primitive_type] : nil
      end

      # Converts the value to ruby from a Neo4j database value if there is a converter for given type
      def to_ruby(value, type = nil)
        found_converter = converters[type]
        found_converter ? found_converter.to_ruby(value) : value
      end

      # Converts the value to a Neo4j database value from ruby if there is a converter for given type
      def to_db(value, type = nil)
        found_converter = converters[type]
        found_converter ? found_converter.to_db(value) : value
      end

      def register_converter(converter)
        converters[converter.convert_type] = converter
      end

      def converters
        @converters ||= begin
          Neo4j::Shared::TypeConverters.constants.each_with_object({}) do |constant_name, result|
            constant = Neo4j::Shared::TypeConverters.const_get(constant_name)
            result[constant.convert_type] = constant if constant.respond_to?(:convert_type)
          end
        end
      end
    end
  end
end
