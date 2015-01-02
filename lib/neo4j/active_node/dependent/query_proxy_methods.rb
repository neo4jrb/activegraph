module Neo4j
  module ActiveNode
    module Dependent
      # methods used to resolve association dependencies
      module QueryProxyMethods
        # Used as part of `dependent: :destroy` and may not have any utility otherwise.
        # It keeps track of the node responsible for a cascading `destroy` process.
        # @param [#dependent_children] caller The node that called this method. Typically, we would use QueryProxy's `caller` method
        # but this is not always available, so we require it explicitly.
        def each_for_destruction(owning_node)
          target = owning_node.called_by || owning_node
          enumerable_query(identity).each do |obj|
            # Cypher can return nil objects, check for empty results
            next if !obj || target.dependent_children.include?(obj)
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
          fail 'Only supported by in QueryProxy chains started by an instance' unless caller
          both_string = "-[:`#{association.relationship_type}`]-"
          in_string = "<#{both_string}"
          out_string = "#{both_string}>"
          primary_rel, inverse_rel =  case association.direction
                                      when :out
                                        [out_string, in_string]
                                      when :in
                                        [in_string, out_string]
                                      else
                                        [both_string, both_string]
                                      end

          query.with(identity).proxy_as_optional(caller.class, self_identifer)
            .send(association.name, other_node, other_rel)
            .where("NOT EXISTS((#{self_identifer})#{primary_rel}(#{other_node})#{inverse_rel}())")
        end
      end
    end
  end
end
