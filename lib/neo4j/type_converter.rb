module Neo4j
  class TypeConverter
    class << self
      #Should return type(class) for which the converter is defined
      def convert_type
        fail 'Not implemented'
      end

      #Should convert an object of the defined type into one of the supported types(primitive types or array)
      def to_db(value)
        fail 'Not implemented'
      end

      #Should convert value into an object of the defined type
      def to_ruby(value)
        fail 'Not implemented'
      end
    end
  end
end
