module Neo4j


  # TODO split up PropertyMixin

  org.neo4j.impl.core.RelationshipProxy.class_eval do
    include Neo4j::JavaPropertyMixin

    # Deletes this relationship.
    #
    # :api: public
    def del
      Neo4j.event_handler.relationship_deleted(wrapper) 
      type = getType().name()

      delete

      if end_node.class.respond_to?(:indexer)
        end_node.class.indexer.on_relationship_deleted(end_node, type)
      elsif end_node.wrapper?
        end_node.wrapper_class.indexer.on_relationship_deleted(end_node, type)
      end
    end

    # :api: public
    def end_node
      id = getEndNode.getId
      Neo4j.load_node(id)
    end

    # :api: public
    def start_node
      id = getStartNode.getId
      Neo4j.load_node(id)
    end

    # :api: public
    def other_node(node)
      neo_node = node
      neo_node = node._java_node if node.respond_to?(:_java_node)
      id = getOtherNode(neo_node).getId
      Neo4j.load_node(id)
    end


    # Returns the neo relationship type that this relationship is used in.
    # (see java API org.neo4j.api.core.Relationship#getType  and org.neo4j.api.core.RelationshipType)
    #
    # ==== Returns
    # Symbol
    #
    # :api: public
    def relationship_type
      get_type.name.to_sym
    end


  end


end
