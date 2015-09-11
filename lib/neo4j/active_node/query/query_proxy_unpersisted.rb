module Neo4j
  module ActiveNode
    module Query
      module QueryProxyUnpersisted
        def defer_create(other_node)
          @start_object.pending_associations << @association.name

          @start_object.association_proxy(@association.name).add_to_cache(other_node)
        end
      end
    end
  end
end
