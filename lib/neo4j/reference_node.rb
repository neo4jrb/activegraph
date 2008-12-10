module Neo4j

  #
  # Holds references to all other nodes
  # The classname of the nodes are used as the name of the relationship to those nodes.
  # There is only one reference node in a neo space, which can always been found (Neo4j::Neo#:ref_node)
  #
  class ReferenceNode
    #    include Neo4j::NodeMixin
    #    include Neo4j::DynamicAccessorMixin
    extend Neo4j::TransactionalMixin
    
    #
    # :api: private
   def initialize(internal_node)
      @internal_node = internal_node
    end

    #
    # Returns a relatio traverser for traversing all types of relation from and to this node
    # @see Neo4j::Relations::RelationTraverser
    #
    # :api: public
    #
    def relations
      Relations::RelationTraverser.new(@internal_node)
    end

    # Connects the given node with the reference node.
    # The type of the relationship will be the same as the class name of the
    # specified node unless the optional parameter type is specified.
    # This method is used internally to keep a reference to all node instances in the node space
    # (useful for example for reindexing all nodes by traversing the node space).
    #
    # ==== Parameters
    # node<Neo4j::NodeMixin>:: Connect the reference node with this node
    # type<String>:: Optinal, the type of the relationship we want to create
    #
    # ==== Returns
    # nil
    #
    # :api: private
    def connect(node, type = node.class.root_class)
      @internal_node.createRelationshipTo(node.internal_node, Neo4j::Relations::RelationshipType.instance(type))
      nil
    end


    transactional :connect
  end

end