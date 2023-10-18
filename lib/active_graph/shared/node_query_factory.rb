module ActiveGraph::Shared
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
end
