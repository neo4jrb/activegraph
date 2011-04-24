# external neo4j dependencies
require 'neo4j/property/property'
require 'neo4j/rels/rels'
require 'neo4j/traversal/traversal'
require 'neo4j/index/index'
require 'neo4j/equal'
require 'neo4j/load'

module Neo4j

  org.neo4j.kernel.impl.core.NodeProxy.class_eval do
    include Neo4j::Property
    include Neo4j::Rels
    include Neo4j::Traversal
    include Neo4j::Equal
    include Neo4j::Index

    def del #:nodoc:
      rels.each {|r| r.del}
      delete
      nil
    end

    def exist?  #:nodoc:
      Neo4j::Node.exist?(self)
    end

    def wrapped_entity  #:nodoc:
      self
    end
    
    def wrapper  #:nodoc:
      self.class.wrapper(self)
    end

    def _java_node  #:nodoc:
      self
    end

    def class  #:nodoc:
      Neo4j::Node
    end
  end


  # A node in the graph with properties and relationships to other entities.
  # Along with relationships, nodes are the core building blocks of the Neo4j data representation model.
  # Node has three major groups of operations: operations that deal with relationships, operations that deal with properties and operations that traverse the node space.
  # The property operations give access to the key-value property pairs.
  # Property keys are always strings. Valid property value types are the primitives(<tt>String</tt>, <tt>Fixnum</tt>, <tt>Float</tt>, <tt>Boolean</tt>), and arrays of those primitives.
  #
  # === Instance Methods form Included Mixins
  # * Neo4j::Property - methods that deal with properties
  # * Neo4j::NodeRelationship methods for relationship
  # * Neo4j::Equal equality operators: <tt>eql?</tt>, <tt>equal</tt>, <tt>==</tt>
  # * Neo4j::Index lucene index methods, like indexing a node
  #
  # === Class Methods from Included Mixins
  # * Neo4j::Index::ClassMethods lucene index class methods, like find
  # * Neo4j::Load - methods for loading a node
  #
  # See also the Neo4j::NodeMixin (Neo4j::Mapping::NodeMixin) if you want to wrap a node with your own Ruby class.
  #
  class Node
    extend Neo4j::Index::ClassMethods
    extend Neo4j::Load

    self.node_indexer self


    ##
    # :method: del
    # Delete the node and all its relationship.
    #
    # It might raise an exception if this method was called without a Transaction,
    # or if it failed to delete the node (it maybe was already deleted).
    #
    # If this method raise an exception you may also get an exception when the transaction finish.
    # This method is  defined in the  org.neo4j.kernel.impl.core.NodeProxy which is return by Neo4j::Node.new
    #
    # ==== Returns
    # nil or raise an exception
    #

    ##
    # :method: exist?
    # returns true if the node exists in the database
    # This method is  defined in the  org.neo4j.kernel.impl.core.NodeProxy which is return by Neo4j::Node.new

    ##
    # :method: wrapped_entity
    # same as _java_node
    # Used so that we have same method for both relationship and nodes
    # This method is  defined in the  org.neo4j.kernel.impl.core.NodeProxy which is return by Neo4j::Node.new

    ##
    # :method: wrapper
    # Loads the Ruby wrapper for this node (unless it is already the wrapper).
    # If there is no _classname property for this node then it will simply return itself.
    # Same as Neo4j::Node.wrapper(node)
    # This method is  defined in the  org.neo4j.kernel.impl.core.NodeProxy which is return by Neo4j::Node.new


    ##
    # :method: _java_node
    # Returns the java node/relationship object representing this object unless it is already the java object.
    # This method is  defined in the  org.neo4j.kernel.impl.core.NodeProxy which is return by Neo4j::Node.new
    
    class << self

      # Returns a new neo4j Node.
      # The return node is actually an Java obejct of type org.neo4j.graphdb.Node java object
      # which has been extended (see the included mixins for Neo4j::Node).
      #
      # The created node will have a unique id - Neo4j::Property#neo_id
      #
      # ==== Parameters
      # *args :: a hash of properties to initialize the node with or nil
      #
      # ==== Returns
      # org.neo4j.graphdb.Node java object
      #
      # ==== Examples
      #
      #  Neo4j::Transaction.run do
      #    Neo4j::Node.new
      #    Neo4j::Node.new :name => 'foo', :age => 100
      #  end
      #
      #
      def new(*args)
        # the first argument can be an hash of properties to set
        props = args[0].respond_to?(:each_pair) && args[0]

        # a db instance can be given, is the first argument if that was not a hash, or otherwise the second
        db = (!props && args[0]) || args[1] || Neo4j.started_db

        node = db.graph.create_node
        props.each_pair { |k, v| node[k]= v } if props
        node
      end

      # create is the same as new
      alias_method :create, :new

      # Loads a node or wrapped node given a native java node or an id.
      # If there is a Ruby wrapper for the node then it will create a Ruby object that will
      # wrap the java node (see Neo4j::NodeMixin).
      #
      # If the node does not exist it will return nil
      #
      def load(node_id, db = Neo4j.started_db)
        node = _load(node_id, db)
        node && node.wrapper
      end

      # Same as load but does not return the node as a wrapped Ruby object.
      #
      def _load(node_id, db = Neo4j.started_db)
        return nil if node_id.nil?
        db.graph.get_node_by_id(node_id.to_i)
      rescue java.lang.IllegalStateException
        nil # the node has been deleted
      rescue org.neo4j.graphdb.NotFoundException
        nil
      end

    end
  end
end
