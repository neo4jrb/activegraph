module Neo4j
  module ActiveNode
    module Dependent
      # methods used to resolve association dependencies
      module QueryProxyMethods
        # Used as part of `dependent: :destroy` and may not have any utility otherwise.
        # It keeps track of the node responsible for a cascading `destroy` process.
        # @param owning_node [#dependent_children] source_object The node that called this method. Typically, we would use QueryProxy's `source_object` method
        # but this is not always available, so we require it explicitly.
        def each_for_destruction(owning_node)
          target = owning_node.called_by || owning_node
          objects = pluck(identity).compact.reject do |obj|
            target.dependent_children.include?(obj)
          end

          objects.each do |obj|
            obj.called_by = target
            target.dependent_children << obj
            yield obj
          end
        end

        # This will match nodes who only have a single relationship of a given type.
        # It's used  by `dependent: :delete_orphans` and `dependent: :destroy_orphans` and may not have much utility otherwise.
        # @param [Neo4j::ActiveNode::HasN::Association] association The Association object used throughout the match.
        # @param [String, Symbol] other_node The identifier to use for the other end of the chain.
        # @param [String, Symbol] other_rel The identifier to use for the relationship in the optional match.
        # @return [Neo4j::ActiveNode::Query::QueryProxy]
        def unique_nodes(association, self_identifer, other_node, other_rel)
          fail 'Only supported by in QueryProxy chains started by an instance' unless source_object
          return false if send(association.name).empty?
          unique_nodes_query(association, self_identifer, other_node, other_rel)
            .proxy_as(association.target_class, other_node)
        end

        private

        def unique_nodes_query(association, self_identifer, other_node, other_rel)
          query.with(identity).proxy_as_optional(source_object.class, self_identifer)
            .send(association.name, other_node, other_rel)
            .query
            .with(other_node)
            .match("()#{association.arrow_cypher(:orphan_rel)}(#{other_node})")
            .with(other_node, count: 'count(*)')
            .where('count = {one}', one: 1)
        end
      end
    end
  end
end
