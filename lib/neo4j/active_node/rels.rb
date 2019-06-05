module Neo4j::ActiveNode
  module Rels
    extend Forwardable
    def_delegators :_rels_delegator, :rel?, :rel, :rels, :node, :nodes, :create_rel

    def _rels_delegator
      fail "Can't access relationship on a non persisted node" unless _persisted_obj
      _persisted_obj
    end

    def delete_reverse_relationship(association)
      reverse_assoc = reverse_association(association)
      self.send("#{reverse_assoc.name}=", nil) if reverse_assoc && reverse_assoc.type == :has_one
    end

    def reverse_association(association)
      reverse_assoc = self.class.associations.find { |_key, assoc| association.inverse_of?(assoc) }
      reverse_assoc && reverse_assoc.last
    end
  end
end
