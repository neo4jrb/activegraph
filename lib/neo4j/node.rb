module Neo4j



  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::Property
    include Neo4j::NodeRelationship
    include Neo4j::Equal
    include Neo4j::Index

    # Delete the node and all its relationship
    def del
      rels.each {|r| r.del}
      delete
    end

    # returns true if the node exists in the database
    def exist?
      Neo4j::Node.exist?(self)
    end

    # same as _java_node
    # Used so that we have same method for both relationship and nodes
    def wrapped_entity
      self
    end
    
    # Loads the Ruby wrapper for this node 
    # If there is no _classname property for this node then it will simply return itself.
    # Same as Neo4j::Node.wrapper(node)
    def wrapper
      self.class.wrapper(self)
    end

    def _java_node
      self
    end

    def class
      Neo4j::Node
    end
  end


  class Node
    extend Neo4j::Index::ClassMethods

    self.indexer self

    class << self
      include Neo4j::Load

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
        wrapper(db.graph.get_node_by_id(node_id.to_i))
      rescue java.lang.IllegalStateException
        nil # the node has been deleted
      rescue org.neo4j.graphdb.NotFoundException
        nil
      end


    end
  end
end
