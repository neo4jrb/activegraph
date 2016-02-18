module Neo4j::ActiveRel::Persistence
  # This class builds and executes a Cypher query, using information from the graph objects to determine
  #   whether they need to be created simultaneously.
  #   It keeps the rel instance from being responsible for inspecting the nodes or talking with Shared::QueryFactory.
  class QueryFactory
    NODE_SYMBOLS = [:from_node, :to_node]
    attr_reader :from_node, :to_node, :rel, :unwrapped_rel

    def initialize(from_node, to_node, rel)
      @from_node = from_node
      @to_node = to_node
      @rel = rel
    end

    # TODO: This feels like it should also wrap the rel, but that is handled in Neo4j::ActiveRel::Persistence at the moment.
    # Builds and executes the query using the objects giving during init.
    # It holds the process:
    #   * Execute node callbacks if needed
    #   * Create and execute the query
    #   * Mix the query response into the unpersisted objects given during init
    def build!
      node_before_callbacks! do
        res = query_factory(rel, rel_id, iterative_query).query.unwrapped.return(*unpersisted_return_ids).first
        node_symbols.each { |n| wrap!(send(n), res, n) }
        @unwrapped_rel = res.send(rel_id)
      end
    end

    private

    def rel_id
      @rel_id ||= rel.rel_identifier
    end

    # Node callbacks only need to be executed if the node is not persisted. We let the `conditional_callback` method do the work,
    #   we only have to give it the type of callback we expect to be run and the condition which, if true, will prevent it from executing.
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

    # Each node must be either created or matched before the relationship can be created. This class does not know or care about
    #   how that happens, it just knows that it needs a usable Neo4j::Core::Query object to do that.
    # This method is "iterative" because it creates one factory for each node but the second builds upon the first.
    def iterative_query
      node_symbols.inject(false) do |iterative_query, sym|
        obj = send(sym)
        query_factory(obj, sym, iterative_query)
      end
    end

    # Isolates the dependency to the shared class. This has an awareness of Neo4j::Core::Query and will match or create
    #   based on the current state of the object passed in.
    def query_factory(obj, sym, factory = false)
      Neo4j::Shared::QueryFactory.create(obj, sym).tap do |factory_instance|
        factory_instance.base_query = factory.blank? ? false : factory.query
      end
    end

    # @return [Array<Symbol>] The Cypher identifiers that will be returned from the query.
    # We only need to return objects from our query that were created during it, otherwise we impact performance.
    def unpersisted_return_ids
      [rel_id].tap do |result|
        node_symbols.each { |k| result << k unless send(k).persisted? }
      end
    end

    # @param [Neo4j::ActiveNode] node A node, persisted or unpersisted
    # @param [Struct] res The result of calling `return` on a Neo4j::Core::Query object. It responds to the same keys
    #   as our graph objects. If the object is unpersisted and was created during the query, the unwrapped node is mixed
    #   in, making the object reflect as "persisted".
    # @param [Symbol] key :from_node or :to_node, the object to request from the response.
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
