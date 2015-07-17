module Neo4j
  module ActiveNode
    module Query
      module QueryProxyUnpersisted
        def defer_create(other_nodes, _properties, operator)
          key = [@association.name, [nil, nil, nil]].hash
          @start_object.pending_associations[key] = [@association.name, operator]
          if @start_object.association_proxy_cache[key]
            @start_object.association_proxy_cache[key] << other_nodes
          else
            @start_object.association_proxy_cache[key] = [other_nodes]
          end
        end
      end
    end
  end
end
