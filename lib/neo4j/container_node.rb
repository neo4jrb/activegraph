module Neo4j

  class ContainerNode
    include NodeMixin
    extend Neo4j::TransactionalMixin

    def init_without_node
      super
      Neo4j.instance.event_handler.add_listener self
    end
    
    # Connects the given node with the reference node.
    # The type of the relationship will be the same as the class name of the
    # specified node unless the optional parameter type is specified.
    # This method is used internally to keep a reference to all node instances in the node space
    # (useful for example for reindexing all nodes by traversing the node space).
    #
    # ==== Parameters
    # node<Neo4j::NodeMixin>:: Connect the reference node with this node
    # type<String>:: Optional, the type of the relationship we want to create
    #
    # ==== Returns
    # nil
    #
    # :api: private
    def connect(node, type = node.class.root_class)
      Transaction.run do
        rtype = Neo4j::Relations::RelationshipType.instance(type)
        @internal_node.createRelationshipTo(node.internal_node, rtype)
      end
      nil
    end

    def on_node_created(node)
      # we have to avoid connecting to our self
      connect(node) unless self == node 
    end

    # transactional :connect
  end

end
