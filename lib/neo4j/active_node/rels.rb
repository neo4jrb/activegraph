module Neo4j::ActiveNode
  module Rels
    extend Forwardable
    def_delegators :_rels_delegator, :rel?, :rel, :rels, :node, :nodes, :create_rel

    def _rels_delegator
      fail "Can't access relationship on a non persisted node" unless _persisted_obj
      _persisted_obj
    end
  end
end
