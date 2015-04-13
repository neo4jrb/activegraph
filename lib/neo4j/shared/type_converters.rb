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

          args = [value.year, value.month, value.day]
          args += (value.class == Date ? [0, 0, 0] : [value.hour, value.min, value.sec])

          Time.utc(*args).to_i
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
      properties.each_pair do |attr, value|
        next if skip_conversion?(attr, value)
        properties[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
      end
    end

    private

    def converted_property(type, value, converter)
      TypeConverters.converters[type].nil? ? value : TypeConverters.to_other(converter, value, type)
    end

    # If the attribute is to be typecast using a custom converter, which converter should it use? If no, returns the type to find a native serializer.
    def primitive_type(attr)
      case
      when self.class.serialized_properties_keys.include?(attr)
        serialized_properties[attr]
      when self.class.magic_typecast_properties_keys.include?(attr)
        self.class.magic_typecast_properties[attr]
      else
        self.class._attribute_type(attr)
      end
    end

    # Returns true if the property isn't defined in the model or it's both nil and unchanged.
    def skip_conversion?(attr, value)
      !self.class.attributes[attr] || (value.nil? && !changed_attributes[attr])
    end

    class << self
      attr_reader :converters

      def included(_)
        return if @converters
        @converters = {}
        Neo4j::Shared::TypeConverters.constants.each do |constant_name|
          constant = Neo4j::Shared::TypeConverters.const_get(constant_name)
          register_converter(constant) if constant.respond_to?(:convert_type)
        end
      end

      def typecaster_for(primitive_type)
        return nil if primitive_type.nil?
        converters.key?(primitive_type) ? converters[primitive_type] : nil
      end

      # @param [Symbol] direction either :to_ruby or :to_other
      def to_other(direction, value, type)
        fail "Unknown direction given: #{direction}" unless direction == :to_ruby || direction == :to_db
        found_converter = converters[type]
        found_converter ? found_converter.send(direction, value) : value
      end

      def register_converter(converter)
        converters[converter.convert_type] = converter
      end
    end
  end
end
