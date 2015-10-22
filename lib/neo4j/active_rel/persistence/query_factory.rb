module Neo4j::ActiveRel::Persistence
  class QueryFactory
    NODE_SYMBOLS = [:from_node, :to_node]
    attr_reader :from_node, :to_node, :rel, :props

    def initialize(graph_objects, props)
      @from_node = graph_objects.fetch(:from_node)
      @to_node = graph_objects.fetch(:to_node)
      @rel = graph_objects.fetch(:rel)
      @props = props
    end

    def rel_id
      @rel_id ||= rel.cypher_identifier
    end

    def build!
      node_before_callbacks! do
        res = query_factory(rel, props, rel_id, iterative_query).query.unwrapped.return(*unpersisted_return_ids).first
        node_symbols.each { |n| wrap!(send(n), res, n) }
        @rel = res.send(rel_id)
      end
    end

    def node_before_callbacks!
      validate_unpersisted_nodes!
      from_node.conditional_callback(:create, from_node.persisted?) do
        to_node.conditional_callback(:create, to_node.persisted?) do
          yield
        end
      end
    end

    def validate_unpersisted_nodes!
      node_symbols.each do |s|
        obj = send(s)
        next if obj.persisted?
        fail RelCreateFailedError, "Cannot create rel with unpersisted, invalid #{s}" unless obj.valid?
      end
    end

    def iterative_query
      node_symbols.inject(false) do |iterative_query, sym|
        obj = send(sym)
        query_factory(obj, obj.props_for_create, sym, iterative_query)
      end
    end

    def query_factory(obj, props, sym, query = false)
      shared_factory(obj, props, sym).tap do |factory_instance|
        factory_instance.base_query = query
      end
    end

    def shared_factory(obj, props, sym)
      Neo4j::Shared::QueryFactory.create(obj, props, sym)
    end

    def unpersisted_return_ids
      [rel_id].tap do |result|
        node_symbols.each { |k| result << k unless send(k).persisted? }
      end
    end

    def wrap!(node, res, key)
      return if node.persisted? || !res.respond_to?(key)
      unwrapped = res.send(key)
      node.init_on_load(unwrapped, unwrapped.props)
    end

    def node_symbols
      self.class::NODE_SYMBOLS
    end
  end
end
