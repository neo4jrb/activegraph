module Neo4j
  module ActiveNode
    module Query
      class QueryProxyPreloader
        attr_reader :queued_methods, :caller, :target_id, :child_id
        delegate :each, :each_with_rel, :each_rel, :to_a, :first, :last, :to_cypher, to: :caller

        def initialize(query_proxy, child_id)
          @caller = query_proxy
          @target_id = caller.identity
          @child_id = child_id || :"#{target_id}_child"
          @queued_methods = {}
        end

        def initial_queue(association_name, given_child_id, rel_id)
          @child_id = given_child_id || :"#{target_id}_child"
          @caller = caller.query.proxy_as_optional(caller.model, target_id).send(association_name, child_id, rel_id)
          caller.instance_variable_set(:@preloader, self)
          queue association_name
          self
        end

        def queue(method_name, *args)
          queued_methods[method_name] = args
          self
        end

        def replay(returned_node, child)
          @chained_node = returned_node
          queued_methods.each { |method, args| @chained_node_association = @chained_node.send(method, *args) }
          cypher_string = @chained_node_association.to_cypher_with_params([@chained_node_association.identity])
          returned_node.association_instance_set(cypher_string, child, returned_node.class.associations[queued_methods.keys.first])
        end
      end
    end
  end
end
