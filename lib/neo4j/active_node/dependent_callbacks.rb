module Neo4j
  module ActiveNode
    module DependentCallbacks
      extend ActiveSupport::Concern

      def dependent_delete_callback(association, ids)
        association_query_proxy(association.name).where(id: ids).delete_all
      end

      def dependent_delete_orphans_callback(association, ids)
        unique_query = as(:self).unique_nodes(association, :self, :n, :other_rel, ids)
        unique_query.query.optional_match('(n)-[r]-()').delete(:n, :r).exec if unique_query
      end

      def dependent_destroy_callback(association, ids)
        unique_query = association_query_proxy(association.name).where(ids: ids)
        unique_query.each_for_destruction(self, &:destroy) if unique_query
      end

      def dependent_destroy_orphans_callback(association, ids)
        unique_query = as(:self).unique_nodes(association, :self, :n, :other_rel, ids)
        unique_query.each_for_destruction(self, &:destroy) if unique_query
      end

      def callbacks_from_active_rel(active_rel, direction, other_node)
        rel = active_rel_corresponding_rel(active_rel, direction, other_node.class).try(:last)
        public_send("dependent_#{rel.dependent}_callback", rel, [other_node.id]) if rel.dependent
      end
    end
  end
end