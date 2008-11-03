module Neo4j

  #
  # Holds references to all other nodes
  # The classname of the nodes are used as the name of the relationship to those nodes.
  # There is only one reference node in a neo space, which can always been found (Neo4j::Neo#:ref_node)
  #
  class ReferenceNode
    #    include Neo4j::NodeMixin
    #    include Neo4j::DynamicAccessorMixin

    def initialize(internal_node)
      @internal_node = internal_node
      #      super
      #      set_property('classname', self.class.to_s) if property?('classname').nil?
    end

    #
    # Returns a relatio traverser for traversing all types of relation from and to this node
    # @see Neo4j::Relations::RelationTraverser
    #
    def relations
      Relations::RelationTraverser.new(@internal_node)
    end

    #
    # Connects the given node with the reference node
    #
    def connect(node)
      clazz = node.class.root_class
      type = Neo4j::Relations::RelationshipType.instance(clazz)
      @internal_node.createRelationshipTo(node.internal_node, type) #if Transaction.running?
    end
  end

end