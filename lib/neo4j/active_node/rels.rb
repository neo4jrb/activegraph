module Neo4j::ActiveNode
  module Rels
    extend Forwardable
    def_delegators :_rels_delegator, :rel?, :rel, :rels, :node, :nodes, :create_rel

    def _rels_delegator
      raise "Can't access relationship on a non persisted node" unless _persisted_node
      _persisted_node
    end
  end
end
