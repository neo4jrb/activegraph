module Neo4j

  module TypeConverters
    class DateConverter
      class << self
        def to_java(value)
          return nil if value.nil?
          Time.utc(value.year, value.month, value.day).to_i
        end

        def to_ruby(value)
          return nil if value.nil?
          Time.at(value).utc
        end
      end
    end

    class DateTimeConverter
      class << self
        # Converts the given DateTime (UTC) value to an Fixnum.
        # Only utc times are supported !
        def to_java(value)
          return nil if value.nil?
          Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec).to_i
        end

        def to_ruby(value)
          return nil if value.nil?
          t = Time.at(value).utc
          DateTime.civil(t.year, t.month, t.day, t.hour, t.min, t.sec)
        end
      end
    end

    # Converts the given value to a Java type by using the registered converters.
    #
    def self.convert(value)
      type      = value.class
      converter = Neo4j::Config[:converters][type]
      return value unless converter
      converter.to_java(value)
    end

    Neo4j::Config[:converters] = {Date => DateConverter, DateTime => DateTimeConverter}
  end
end
