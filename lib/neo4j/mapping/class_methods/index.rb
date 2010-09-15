module Neo4j::Mapping
  module ClassMethods
    module Index
      def index(field, props = {})
        props[:prefix] = index_prefix
        Neo4j::Node.index(field, props)
      end

      def find(field, query, props = {})
        props[:prefix] = index_prefix
        Neo4j::Node.find(field, query, props)
      end

      def rm_index(field, props = {})
        props[:prefix] = index_prefix
        Neo4j::Node.rm_index(field, props)
      end

      def index_prefix
        root_class
      end
    end
  end
end
