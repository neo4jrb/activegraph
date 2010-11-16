module Neo4j

  # Responsible for converting values from and to Java Neo4j and Lucene.
  # You can implement your own converter by implementing the method <tt>to_java</tt> and <tt>to_ruby</tt>
  # and add it to the Neo4j::Config with the key <tt>:converters</tt>
  #
  # There are currently two default converters that are triggered when a Date or a DateTime is read or written.
  #
  module TypeConverters

  	# The default converter to use if there isn't a specific converter for the type
  	class DefaultConverter
  		class << self
  			def to_java(value)
  				value
  			end
  			
  			def to_ruby(value)
  				value
  			end
  		end
  	end
  	
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

    class << self
			# Always returns a converter that handles to_ruby or to_java
			def converter(type = nil)
				Neo4j.converters[type] || DefaultConverter
			end
				
			# Converts the given value to a Java type by using the registered converters.
			# It just looks at the class of the given value unless an attribute name is given.
			# It will convert it if there is a converter registered (in Neo4j::Config) for this value.
			def convert(value, attribute = nil, klass = nil)
				converter(attribute_type(value, attribute, klass)).to_java(value)
			end
	
			# Converts the given property (key, value) to Java by using configuration from the given class.
			# If no Converter is defined for this value then it simply returns the given value.
			def to_java(clazz, key, value)
				type = clazz._decl_props[key.to_sym] && clazz._decl_props[key.to_sym][:type]
				converter(type).to_java(value)
			end
	
			# Converts the given property (key, value) to Ruby by using configuration from the given class.
			# If no Converter is defined for this value then it simply returns the given value.
			def to_ruby(clazz, key, value)
				type = clazz._decl_props[key.to_sym] && clazz._decl_props[key.to_sym][:type]
				converter(type).to_ruby(value)
			end
			
			private
			def attribute_type(value, attribute = nil, klass = nil)
				type = (attribute && klass) ? attribute_type_from_attribute_and_klass(value, attribute, klass) : nil
				type || attribute_type_from_value(value)
			end
			
			def attribute_type_from_attribute_and_klass(value, attribute, klass)
				if klass.respond_to?(:_decl_props)
					(klass._decl_props.has_key?(attribute) && klass._decl_props[attribute][:type]) ? klass._decl_props[attribute][:type] : nil
				end
			end
			
			def attribute_type_from_value(value)
				value.class
			end
		end
  end
end
