module Neo4j::Shared
  # Acts as a bridge between the node and rel models and Neo4j::Core::Query.
  # If the object is persisted, it returns a query matching; otherwise, it returns a query creating it.
  class QueryFactory
    attr_reader :graph_object, :props, :identifier

    def initialize(graph_object, props, identifier)
      @graph_object = graph_object
      @props = props
      @identifier = identifier.to_sym
    end

    def self.create(graph_object, props, identifier)
      factory = case graph_object
                when Neo4j::ActiveNode
                  NodeQueryFactory
                when Neo4j::ActiveRel
                  RelQueryFactory
                else
                  fail "Unable to find factory for #{graph_object}"
                end
      factory.new(graph_object, props, identifier)
    end

    def query
      graph_object.persisted? ? match_query : create_query
    end

    def base_query=(query)
      return if query.blank?
      @base_query = query.query
    end

    def base_query
      @base_query || Neo4j::Session.current.query
    end

    protected

    def create_query
      fail 'Abstract class, not implemented'
    end

    def match_query
      base_query
        .match(identifier).where("ID(#{identifier}) = {#{identifier_id}}")
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

    def create_query
      return match_query if graph_object.persisted?
      base_query.create(identifier => {graph_object.labels_for_create.join(':').to_sym => graph_object.props_for_create})
    end
  end

  class RelQueryFactory < QueryFactory

    protected

    def create_query
      return match_query if graph_object.persisted?
      base_query.send(graph_object.create_method, query_string).params(identifier_params.to_sym => props)
    end

    private

    def query_string
      "#{graph_object.from_node_identifier}-[#{identifier}:#{graph_object.type} {#{identifier_params}}]->#{graph_object.to_node_identifier}"
    end
  end
end
