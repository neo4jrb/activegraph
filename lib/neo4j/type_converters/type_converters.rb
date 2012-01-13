module Neo4j

  # Responsible for converting values from and to Java Neo4j and Lucene.
  # You can implement your own converter by implementing the method <tt>convert?</tt>
  # <tt>to_java</tt> and <tt>to_ruby</tt> in this module.
  #
  # There are currently three default converters that are triggered when a Time, Date or a DateTime is read or written
  # if there is a type declared for the property.
  #
  # ==== Example
  #
  # Example of writing your own marshalling converter:
  #
  #  class Foo
  #     include Neo4j::NodeMixin
  #     property :thing, :type => MyType
  #  end
  #
  #  module Neo4j::TypeConverters
  #    class MyTypeConverter
  #      class << self
  #        def convert?(type)
  #          type == MyType
  #        end
  #
  #        def to_java(val)
  #          "silly:#{val}"
  #        end
  #
  #        def to_ruby(val)
  #          val.sub(/silly:/, '')
  #        end
  #      end
  #    end
  #  end
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


    class BooleanConverter
      class << self

        def convert?(class_or_symbol)
          :boolean == class_or_symbol
        end

        def to_java(value)
          return nil if value.nil?
          !!value && value != '0'
        end

        def to_ruby(value)
          return nil if value.nil?
          !!value && value != '0'
        end
      end
    end

    class SymbolConverter
      class << self

        def convert?(class_or_symbol)
          :symbol == class_or_symbol || Symbol == class_or_symbol
        end

        def to_java(value)
          return nil if value.nil?
          value.to_s
        end

        def to_ruby(value)
          return nil if value.nil?
          value.to_sym
        end
      end
    end


    class StringConverter
      class << self

        def convert?(class_or_symbol)
          [String, :string, :text].include? class_or_symbol
        end

        def to_java(value)
          return nil if value.nil?
          value.to_s
        end

        def to_ruby(value)
          return nil if value.nil?
          value.to_s
        end
      end
    end



    class FixnumConverter
      class << self

        def convert?(class_or_symbol)
          Fixnum == class_or_symbol || :fixnum == class_or_symbol || :numeric == class_or_symbol
        end

        def to_java(value)
          return nil if value.nil?
          value.to_i
        end

        def to_ruby(value)
          return nil if value.nil?
          value.to_i
        end
      end
    end

    class FloatConverter
      class << self

        def convert?(clazz_or_symbol)
          Float == clazz_or_symbol || :float == clazz_or_symbol
        end

        def to_java(value)
          return nil if value.nil?
          value.to_f
        end

        def to_ruby(value)
          return nil if value.nil?
          value.to_f
        end
      end
    end

    # Converts Date objects to Java long types. Must be timezone UTC.
    class DateConverter
      class << self

        def convert?(clazz_or_symbol)
          Date == clazz_or_symbol || :date == clazz_or_symbol
        end

        def to_java(value)
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

        def convert?(clazz_or_symbol)
          DateTime == clazz_or_symbol || :datetime == clazz_or_symbol
        end

        # Converts the given DateTime (UTC) value to an Fixnum.
        # Only utc times are supported !
        def to_java(value)
          return nil if value.nil?
          if value.class == Date
            Time.utc(value.year, value.month, value.day, 0, 0, 0).to_i
          else
            Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec).to_i
          end
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

        def convert?(clazz_or_symbol)
          Time == clazz_or_symbol || :time == clazz_or_symbol
        end

        # Converts the given DateTime (UTC) value to an Fixnum.
        # Only utc times are supported !
        def to_java(value)
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

    class << self

      # Mostly for testing purpose, You can use this method in order to
      # add a converter while the neo4j has already started.
      def converters=(converters)
        @converters = converters
      end
      
      # Always returns a converter that handles to_ruby or to_java
      # if +enforce_type+ is set to false then it will raise in case of unknown type
      # otherwise it will return the DevaultConverter.
      def converter(type = nil, enforce_type = true)
        return DefaultConverter unless type
        @converters ||= begin
          Neo4j::TypeConverters.constants.find_all do |c|
            Neo4j::TypeConverters.const_get(c).respond_to?(:convert?)
          end.map do  |c|
            Neo4j::TypeConverters.const_get(c)
          end
        end
        found = @converters.find {|c| c.convert?(type) }
        raise "The type #{type.inspect} is unknown. Use one of #{@converters.map{|c| c.name.demodulize.sub('Converter','') }.join(", ")} or create a custom type converter." if !found && enforce_type
        found or DefaultConverter
      end

      # Converts the given value to a Java type by using the registered converters.
      # It just looks at the class of the given value unless an attribute name is given.
      # It will convert it if there is a converter registered (in Neo4j::Config) for this value.
      def convert(value, attribute = nil, klass = nil, enforce_type = true)
        converter(attribute_type(value, attribute, klass), enforce_type).to_java(value)
      end

      # Converts the given property (key, value) to Java if there is a type converter for given type.
      # The type must also be declared using Neo4j::NodeMixin#property property_name, :type => clazz
      # If no Converter is defined for this value then it simply returns the given value.
      def to_java(clazz, key, value)
        type = clazz._decl_props[key.to_sym] && clazz._decl_props[key.to_sym][:type]
        converter(type).to_java(value)
      end

      # Converts the given property (key, value) to Ruby if there is a type converter for given type.
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
