module Neo4j
  module ActiveNode
    module Query
      class QueryProxyPreloader
        attr_reader :queued_methods, :caller, :target_id, :child_id
        delegate :each, :each_with_rel, :each_rel, :to_a, :first, :last, :to_cypher, to: :caller

        def initialize(query_proxy, target_id, child_id)
          @caller = query_proxy
          @target_id = target_id
          @child_id = child_id
          @queued_methods = {}
        end

        def queue(method_name, *args)
          queued_methods[method_name] = args
          self
        end

        def replay(returned_node, child)
          @chained_node = returned_node
          queued_methods.each { |method, args| @chained_node = @chained_node.send(method, *args) }
          cypher_string = @chained_node.to_cypher_with_params([@chained_node.identity])
          returned_node.association_instance_set(cypher_string, child, returned_node.class.associations[queued_methods.keys.first])
        end
      end
    end
  end
end
