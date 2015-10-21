module Neo4j::ActiveRel::Persistence
  class Factory
    attr_reader :from_node, :to_node, :rel, :props

    def initialize(graph_objects, props)
      @from_node = graph_objects.fetch(:from_node)
      @to_node = graph_objects.fetch(:to_node)
      @rel = graph_objects.fetch(:rel)
      @props = props
    end
  end
end
