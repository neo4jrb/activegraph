module Neo4j
  module ActiveNode
    module Query
      class QueryProxyPreloader
        attr_reader :queued_methods, :caller, :target_id, :child_id, :rel_id, :proxy, :last_association
        delegate :each, :each_with_rel, :each_rel, :to_a, :first, :last, :to_cypher, to: :caller

        def initialize(query_proxy, _given_child_id)
          @caller = query_proxy
          @target_id = caller.identity
          @child_id = child_id || :"#{target_id}_child"
          @last_association = query_proxy.association
          @queued_methods = {}
        end

        def initial_queue(association_name, given_child_id, given_rel_id)
          @child_id = given_child_id || child_id
          @rel_id = given_rel_id || caller.rel_var
          node_caller = caller.caller
          @caller = caller.query.proxy_as_optional(caller.model, target_id).send(association_name, child_id, given_rel_id)
          caller.inject_caller(node_caller)
          caller.instance_variable_set(:@preloader, self)
          queue association_name
          @proxy = QueryProxyProxy.new(caller)
          self
        end

        def queue(method_name, *args)
          queued_methods[method_name] = args
        end

        def replay(returned_node, child)
          replay_queued(returned_node)
          association_obj = returned_node.class.associations[queued_methods.keys.first]
          returned_node.association_instance_set(replay_cypher_string([@chained_node_association.identity]), child, association_obj)
        end

        def replay_with_rel(returned_node, child, child_rel)
          replay_queued(returned_node)
          stash = [child + child_rel]
          association_obj = returned_node.class.associations[queued_methods.keys.first]
          returned_node.association_instance_set(replay_cypher_string([@chained_node_association.identity, rel_id]), stash, association_obj)
        end

        private

        def replay_cypher_string(params_array)
          @chained_node_association.to_cypher_with_params(params_array)
        end

        def replay_queued(returned_node)
          @chained_node = returned_node
          queued_methods.each { |method, args| @chained_node_association = @chained_node.send(method, *args) }
        end
      end
    end
  end
end
