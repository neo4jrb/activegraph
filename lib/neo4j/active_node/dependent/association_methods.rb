module Neo4j
  module ActiveNode
    module Dependent
      module AssociationMethods
        def add_destroy_callbacks(model)
          return if dependent.nil?
          # Bound value for procs
          assoc = self

          fn = case dependent
               when :delete
                 proc { |o| o.send("#{assoc.name}_query_proxy").delete_all }
               when :delete_orphans
                 proc { |o| o.as(:self).unique_nodes(assoc, :self, :n, :other_rel).query.delete(:n, :other_rel).exec }
               when :destroy
                 proc { |o| o.send("#{assoc.name}_query_proxy").each_for_destruction(o) { |node| node.destroy } }
               when :destroy_orphans
                 proc { |o| o.as(:self).unique_nodes(assoc, :self, :n, :other_rel).each_for_destruction(o) { |node| node.destroy } }
               else
                 fail "Unknown dependent option #{dependent}"
               end

          model.before_destroy fn
        end
      end
    end
  end
end
