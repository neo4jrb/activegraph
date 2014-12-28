module Neo4j::Shared
  module TypeConverters

    # Converts Date objects to Java long types. Must be timezone UTC.
    class DateConverter
      class << self

        def convert_type
          Date
        end

        def to_db(value)
          return nil if value.nil?
          Time.utc(value.year, value.month, value.day).to_i
        end

        def to_ruby(value)
          return nil if value.nil?
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

        # Converts the given DateTime (UTC) value to an Fixnum.
        # DateTime values are automatically converted to UTC.
        def to_db(value)
          return nil if value.nil?
          value = value.new_offset(0) if value.respond_to?(:new_offset)
          if value.class == Date
            Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
          else
            Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec).to_i
          end
        end

        def to_ruby(value)
          return nil if value.nil?
          t = case value
              when Fixnum
                Time.at(value).utc
              when String
                DateTime.strptime(value, '%Y-%m-%d %H:%M:%S %z')
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

        # Converts the given DateTime (UTC) value to an Fixnum.
        # Only utc times are supported !
        def to_db(value)
          return nil if value.nil?
          if value.class == Date
            Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
          else
            value.utc.to_i
          end
        end

        def to_ruby(value)
          return nil if value.nil?
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
          return nil if value.nil?
          Psych.dump(value)
        end

        def to_ruby(value)
          return nil if value.nil?
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
          return nil if value.nil?
          value.to_json
        end

        def to_ruby(value)
          return nil if value.nil?
          JSON.parse(value, quirks_mode: true)
        end
      end
    end



    def convert_properties_to(medium, properties)
      # Perform type conversion
      serialize = self.respond_to?(:serialized_properties) ? self.serialized_properties : {}
      properties = properties.inject({}) do |new_attributes, key_value_pair|
        attr, value = key_value_pair

        # skip "secret" undeclared attributes such as uuid
        next new_attributes unless self.class.attributes[attr]

        type = serialize.key?(attr.to_sym) ? serialize[attr.to_sym] : self.class._attribute_type(attr)
        new_attributes[attr] = if TypeConverters.converters[type].nil?
                                 value
                               else
                                 TypeConverters.send "to_#{medium}", value, type
                                end
        new_attributes
      end
    end

    class << self

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

      def converters
        @converters ||= begin
          Neo4j::Shared::TypeConverters.constants.find_all do |c|
            Neo4j::Shared::TypeConverters.const_get(c).respond_to?(:convert_type)
          end.map do  |c|
            Neo4j::Shared::TypeConverters.const_get(c)
          end.inject({}) do |ack, t|
            ack[t.convert_type] = t
            ack
          end
        end
      end
    end
  end
end
