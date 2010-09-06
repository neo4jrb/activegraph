module Neo4j



  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::Property
    include Neo4j::Relationship
    include Neo4j::Equal
    include Neo4j::Index
  end


  class Node

    class << self
      def new(*args)
        # creates a new node using the default db instance when given no args

        # the first argument can be an hash of properties to set
        props = args[0].respond_to?(:each_pair) && args[0]

        # a db instance can be given, is the first argument if that was not a hash, or otherwise the second
        db = (!props && args[0]) || args[1] || Neo4j.db
        create(props, db)
      end

      def create(props, db = Neo4j.db)
        node = db.graph.create_node
        props.each_pair { |k, v| node.set_property(k.to_s, v) } if props
        node
      end


      def load(node_id, db = Neo4j.db)
        node = db.graph.get_node_by_id(node_id.to_i)
        return node unless node.property?(:_classname)
        classname = node[:_classname]
        clazz = classname.split("::").inject(Kernel) {|container, name| container.const_get(name.to_s) }
        clazz.new(node)
      rescue org.neo4j.graphdb.NotFoundException
        nil
      end

      def exist?(node_or_node_id, db = Neo4j.db)
        id = node_or_node_id.respond_to?(:id) ? node_or_node_id.id : node_or_node_id
        load(id, db) != nil
      end

      def find(field, query, db=Neo4j.db)
        db.lucene.get_nodes(field.to_s, query)
      end

      # Adds a global index. Will use the event framework in order to keep the property in sync with
      # the lucene database
      def index(field, db=Neo4j.db)
        db.index(field)
      end

      def rm_index(field, db=Neo4j.db)
        db.rm_index(field)
      end
    end
  end
end