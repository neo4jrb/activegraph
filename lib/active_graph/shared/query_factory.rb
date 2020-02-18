module ActiveGraph::Shared
  # Acts as a bridge between the node and rel models and ActiveGraph::Core::Query.
  # If the object is persisted, it returns a query matching; otherwise, it returns a query creating it.
  # This class does not execute queries, so it keeps no record of what identifiers have been set or what has happened in previous factories.
  class QueryFactory
    attr_reader :graph_object, :identifier

    def initialize(graph_object, identifier)
      @graph_object = graph_object
      @identifier = identifier.to_sym
    end

    def self.create(graph_object, identifier)
      factory_for(graph_object).new(graph_object, identifier)
    end

    def self.factory_for(graph_obj)
      case
      when graph_obj.respond_to?(:labels_for_create)
        NodeQueryFactory
      when graph_obj.respond_to?(:rel_type)
        RelQueryFactory
      else
        fail "Unable to find factory for #{graph_obj}"
      end
    end

    def query
      graph_object.persisted? ? match_query : create_query
    end

    # @param [ActiveGraph::Core::Query] query An instance of ActiveGraph::Core::Query upon which methods will be chained.
    def base_query=(query)
      return if query.blank?
      @base_query = query
    end

    def base_query
      @base_query || ActiveGraph::ActiveBase.new_query
    end

    protected

    def create_query
      fail 'Abstract class, not implemented'
    end

    def match_query
      base_query
        .match(match_string).where("ID(#{identifier}) = $#{identifier_id}")
        .params(identifier_id.to_sym => graph_object.neo_id)
    end

    def identifier_id
      @identifier_id ||= "#{identifier}_id"
    end

    def identifier_params
      @identifier_params ||= "#{identifier}_params"
    end
  end

  class NodeQueryFactory < QueryFactory
    protected

    def match_string
      "(#{identifier})"
    end

    def create_query
      return match_query if graph_object.persisted?
      labels = graph_object.labels_for_create.map { |l| ":`#{l}`" }.join
      base_query.create("(#{identifier}#{labels} $#{identifier}_params)").params(identifier_params => graph_object.props_for_create)
    end
  end

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
