module ActiveGraph::Shared
  class RelQueryFactory < QueryFactory
    protected

    def match_pattern
      node(graph_object.from_node_identifier).relationship_to(node).named(identifier)
    end

    def create_query
      return match_query if graph_object.persisted?
      create_props, set_props = filtered_props
      base_query.send(graph_object.create_method, create_pattern(create_props)).break
                .set(identifier => set_props)
    end

    private

    def filtered_props
      ActiveGraph::Shared::FilteredHash.new(graph_object.props_for_create, graph_object.creates_unique_option).filtered_base
    end

    # `(from)-[rel:`TYPE` {key: $rel_create_props_key, …}]->(to)`; the properties named in the
    # `unique` option are part of the pattern so that MERGE matches on them.
    def create_pattern(create_props)
      pattern = node(graph_object.from_node_identifier)
                .relationship_to(node(graph_object.to_node_identifier), graph_object.type)
                .named(identifier)
      return pattern if create_props.empty?

      pattern.with_properties(create_props.to_h { |key, value| [key, parameter(scoped(key), value)] })
    end

    def scoped(key)
      "#{identifier}_create_props_#{key}"
    end
  end
end
