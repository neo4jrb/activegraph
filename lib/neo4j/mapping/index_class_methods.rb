module Neo4j
  module Mapping
    module IndexClassMethods
      def index(field, props = {})
        key = "#{root_class}::#{field}"
        puts "add #{field} filter #{key}"
        props[:class] = root_class
        Neo4j::Node.index(field, props)
      end

      def find(field, query)
        key = "#{root_class}:#{field}"
        puts "search index #{key}"
        Neo4j::Node.find(key, query)
      end

      def rm_index(field)
        Neo4j::Node.rm_index(field)
      end
    end
  end
end