module Neo4j

  # Responsible for converting values from and to Java Neo4j and Lucene.
  # You can implement your own converter by implementing the method <tt>to_java</tt> and <tt>to_ruby</tt>
  # and add it to the Neo4j::Config with the key <tt>:converters</tt>
  #
  # There are currently two default converters that are triggered when a Date or a DateTime is read or written.
  #
  module TypeConverters

    # Converts Date objects to Java long types. Must be timezone UTC.
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

    # Converts DateTime objects to and from Java long types. Must be timezone UTC.
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
    
    class TimeConverter
    	class << self
    		# Converts the given DateTime (UTC) value to an Fixnum.
        # Only utc times are supported !
        def to_java(value)
          return nil if value.nil?
          value.utc.to_i
        end

        def to_ruby(value)
          return nil if value.nil?
          Time.at(value).utc
        end
    	end
    end

    # Converts the given value to a Java type by using the registered converters.
    # It just looks at the class of the given value and will convert it if there is a converter
    # registered (in Neo4j::Config) for this value.
    def self.convert(value)
      type      = value.class
      converter = Neo4j.converters[type]
      return value unless converter
      converter.to_java(value)
    end

    # Converts the given property (key, value) to Java by using configuration from the given class.
    # If no Converter is defined for this value then it simply returns the given value.
    def self.to_java(clazz, key, value)
      type = clazz._decl_props[key.to_sym] && clazz._decl_props[key.to_sym][:type]
      if type
        converter = Neo4j.converters[type]
        converter ? converter.to_java(value) : value
      else
        value
      end
    end

    # Converts the given property (key, value) to Ruby by using configuration from the given class.
    # If no Converter is defined for this value then it simply returns the given value.
    def self.to_ruby(clazz, key, value)
      type = clazz._decl_props[key.to_sym] && clazz._decl_props[key.to_sym][:type]
      if type
        converter = Neo4j.converters[type]
        converter ? converter.to_ruby(value) : value
      else
        value
      end
    end
  end
end
