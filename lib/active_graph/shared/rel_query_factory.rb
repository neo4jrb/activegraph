module ActiveGraph::Shared
  class RelQueryFactory < QueryFactory
    protected

    def match_string
      "(#{graph_object.from_node_identifier})-[#{identifier}]->()"
    end

    def create_query
      return match_query if graph_object.persisted?
      create_props, set_props = filtered_props
      base_query.send(graph_object.create_method, query_string(create_props)).break
                .set(identifier => set_props)
                .params(params(create_props))
    end

    private

    def filtered_props
      ActiveGraph::Shared::FilteredHash.new(graph_object.props_for_create, graph_object.creates_unique_option).filtered_base
    end

    def query_string(create_props)
      "(#{graph_object.from_node_identifier})-[#{identifier}:`#{graph_object.type}` #{pattern(create_props)}]->(#{graph_object.to_node_identifier})"
    end

    def params(create_props)
      unique? ? create_props.transform_keys { |key| scoped(key).to_sym } : { namespace.to_sym => create_props }
    end

    def unique?
      graph_object.create_method == :create_unique
    end

    def pattern(create_props)
      unique? ? "{#{create_props.keys.map { |key| "#{key}: $#{scoped(key)}" }.join(', ')}}" : "$#{namespace}"
    end

    def scoped(key)
      "#{namespace}_#{key}"
    end

    def namespace
      "#{identifier}_create_props"
    end
  end
end
