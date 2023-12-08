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
      when graph_obj.respond_to?(:type)
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
      @base_query || ActiveGraph::Base.new_query
    end

    protected

    def create_query
      fail 'Abstract class, not implemented'
    end

    def match_query
      base_query
        .match(match_string).where("elementId(#{identifier}) = $#{identifier_id}")
        .params(identifier_id.to_sym => graph_object.neo_id)
    end

    def identifier_id
      @identifier_id ||= "#{identifier}_id"
    end

    def identifier_params
      @identifier_params ||= "#{identifier}_params"
    end
  end
end
