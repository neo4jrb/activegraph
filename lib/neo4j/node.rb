module Neo4j



  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::Property
    include Neo4j::NodeRelationship
    include Neo4j::Equal
    include Neo4j::Index

    # Delete the node and all its relationship
    def del
      rels.each {|r| r.delete}
      delete
    end

    # returns true if the node exists in the database
    def exist?
      Neo4j::Node.exist?(self)
    end
  end


  class Node

    class << self

      # Creates a new node using the default db instance when given no args
      # Same as Neo4j::Node#create
      def new(*args)
        # the first argument can be an hash of properties to set
        props = args[0].respond_to?(:each_pair) && args[0]

        # a db instance can be given, is the first argument if that was not a hash, or otherwise the second
        db = (!props && args[0]) || args[1] || Neo4j.started_db

        node = db.graph.create_node
        props.each_pair { |k, v| node.set_property(k.to_s, v) } if props
        node
      end

      # create is the same as new
      alias_method :create, :new

      def load(node_id, db = Neo4j.started_db)
        load_wrapper(db.graph.get_node_by_id(node_id.to_i))
      rescue java.lang.IllegalStateException
        nil # the node has been deleted
      rescue org.neo4j.graphdb.NotFoundException
        nil
      end

      def load_wrapper(node)
        return node unless node.property?(:_classname)
        to_class(node[:_classname]).load_wrapper(node)
      end

      def to_class(class_name)
        class_name.split("::").inject(Kernel) {|container, name| container.const_get(name.to_s) }
      end

      def exist?(node_or_node_id, db = Neo4j.started_db)
        id = node_or_node_id.kind_of?(Fixnum) ?  node_or_node_id : node_or_node_id.id
        load(id, db) != nil
      end

      def find(field, query, props=nil, db=Neo4j.started_db)
        db.find(field.to_s, query, props)
      end

      # Adds a global index. Will use the event framework in order to keep the property in sync with
      # the lucene database
      def index(field, props=nil, db = Neo4j.default_db)
        db.index(field, props)
      end

      def rm_index(field, props=nil, db=Neo4j.default_db)
        db.rm_index(field, props)
      end
    end
  end
end
