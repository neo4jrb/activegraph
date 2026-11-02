module ActiveGraph::Shared
  class NodeQueryFactory < QueryFactory
    protected

    def match_pattern
      node(identifier)
    end

    # `CREATE (n:`Label`) SET n = $n_params`: the whole property map travels as one parameter,
    # so the Cypher text (and the query plan) is the same for every instance of a model.
    def create_query
      return match_query if graph_object.persisted?
      created = CypherDSL::Cypher.node(*graph_object.labels_for_create).named(identifier)
      base_query.create(created).set(created.set(props_parameter)).break
    end

    def props_parameter
      parameter(identifier_params, graph_object.props_for_create)
    end
  end
end
