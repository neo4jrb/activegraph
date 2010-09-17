module Neo4j::Mapping
  module ClassMethods
    module Index
      def index(field, config = {})
        Neo4j::Node.index(field, config, index_name)
      end

      def find(field, query, config = {})
        Neo4j::Node.find(field, query, config, index_name)
      end

      def rm_index(field, config = {})
        Neo4j::Node.rm_index(field, config, index_name)
      end

      def index_name
        root_class
      end
    end
  end
end
