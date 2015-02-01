module Neo4j
  module ActiveNode
    module Query
      # A QueryProxyPreloader is created after calling `:includes` on a QueryProxy chain.
      # It captures changes to the QueryProxy chain after `:includes` is called, since these need to be replayed carefully to
      # insert the returned nodes and rels (if requested) into the "target" nodes' association cache.
      #
      # It helps to understand how the association cache works to make sense of this. Check out Neo4j::ActiveNode::HasN::AssociationCache for more info.
      #
      # The short version here is that we are exploiting the behavior of the association cache, filling it with the result of a query before
      # the user explicitly returns `node.association`. Normally, you have to return a QueryProxy to populate a node's association cache. The first
      # query will fill the cache, the second will use it. Preloading works by taking the Cypher match that would normally occur as a result of
      # calling `node.association` and adding an OPTIONAL MATCH to it, then taking the results of the OPTIONAL MATCH and stashing them in the associated
      # node's association cache before those nodes make the request.
      #
      # In practice, it looks like this:
      #   lessons = student.lessons.includes(:teachers).to_a
      #   # generates cypher:
      #   # MATCH (student:Student)-[:ENROLLED_IN]->(lesson:Lesson) OPTIONAL MATCH (lesson)-[:TAUGHT_BY]->(teacher:Teacher) RETURN lesson, COLLECT(teacher)
      #   lessons.each do |lesson|
      #     # lesson's association cache already has its teachers loaded
      #     lesson.teachers.each do |teacher|
      #       # a new query was not performed! We already have the teachers!
      #       teacher.name
      #     end
      #   end
      class QueryProxyPreloader
        attr_reader :queued_methods, :caller, :target_id, :child_id, :rel_id, :proxy, :last_association
        delegate :each, :each_with_rel, :each_rel, :to_a, :first, :last, :to_cypher, to: :caller

        # During initialization, we capture pieces of the QueryProxy before making changes to it and set a few variables
        # * `caller`, the untouched QueryProxy
        # * `target_id`, the Cypher ID of the original target of the QueryProxy chain before `includes` was called
        # * `child_id`, the Cypher ID to use for the preload Cypher MATCH
        # * `rel_id`, the Cypher ID of the relationship between the target and the link of the QP chain that called it.
        # * `last_association`, the QueryProxy association that was called as part of the QueryProxy chain, if one exists
        # * `queued_methods`, a hash that will contain methods called on the preloaded association
        # @param [#to_cypher] query_proxy The QueryProxy object as it existed before this object was created
        # @param [String, Symbol] given_rel_id The identifier used for the relationship between target and child.
        def initialize(query_proxy, given_child_id = nil)
          @caller = query_proxy
          @target_id = caller.identity
          @child_id = given_child_id || :"#{target_id}_child"
          @rel_id = caller.rel_var
          @last_association = query_proxy.association
          @queued_methods = {}
        end

        # The initial queue sets up the first, most important, pieces of the OPTIONAL MATCH used to "preload" associations.
        # @param [String, Symbol] association_name The association name given to `includes`
        # @param [String, Symbol] given_child_id The identifier used for the "child" in the Cypher query. The child is the target of the new match.
        # @param [Boolean] optional Controls whether this query will use OPTIONAL MATCH or MATCH.
        def initial_queue(association_name, given_rel_id, optional)
          # Unfortunate naming here. The first `caller` is the original QP object, the second is the node that started the query, if one exists.
          build_new_qp(optional) do |query_method|
            @caller = caller.query.send(query_method, caller.model, target_id).send(association_name, child_id, given_rel_id)
          end
          queue association_name
          @proxy = QueryProxyProxy.new(caller)
          self
        end

        # Builds the same QueryProxy object that would have been built, had the association called during `includes` been called on
        # the node passed in as `returned_node`.
        # @param [#neo_id] returned_node A wrapped node returned by a QueryProxy that will have its association cache preloaded with content.
        # @param [#neo_id, Array] collection A node or array of arrays containing nodes returned by a QueryProxy using `includes`. This is the content
        # to be loaded into the returned node's association cache.
        # @param [Boolean] rel Indicates whether a rel has been requested during replay. It is significant because it changes the final Cypher string generated
        # to fake the association cache's Cypher hash.
        def replay(returned_node, collection, rel = false)
          params = replay_queued(returned_node, rel)
          association_obj = returned_node.class.associations[queued_methods.keys.first]
          returned_node.association_instance_set(replay_cypher_string(params), collection, association_obj)
        end

        private

        def build_new_qp(optional)
          node_caller = caller.caller
          yield optional ? :proxy_as_optional : :proxy_as
          caller.inject_caller(node_caller)
          caller.instance_variable_set(:@preloader, self)
        end

        # To insert the eagerly loaded nodes and rels into the target's association cache, we need to replay every action called during/after `includes`.
        # The `queued_methods` hash holds those. We can use `queue` to set that.
        def queue(method_name, *args)
          queued_methods[method_name] = args
        end

        def replay_cypher_string(params_array)
          @chained_node_association.to_cypher_with_params(params_array)
        end

        def replay_queued(returned_node, rel)
          @chained_node = returned_node
          queued_methods.each { |method, args| @chained_node_association = @chained_node.send(method, *args) }
          rel ? [@chained_node_association.identity, rel_id] : [@chained_node_association.identity]
        end
      end
    end
  end
end
