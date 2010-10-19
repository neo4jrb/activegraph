module Neo4j
  module Index
    class IndexerRegistry #:nodoc:
      class << self
        def create_for(this_clazz, using_other_clazz, type)
          @@indexers ||= {}
          @@indexers[this_clazz.to_s] = @@indexers[using_other_clazz.to_s] || Indexer.new(this_clazz, type)
          @@indexers[this_clazz.to_s]
        end

        def find_by_class(classname)
          @@indexers[classname]
        end

        def on_node_created(node)
#          puts "IndexerRegistry: on_node_created #{node}"
#          indexer = find_by_class(node['_classname'])
#          puts "indexer=#{indexer}"
#          indexer.add_index_on_all_fields(node) if indexer
        end

        def on_node_deleted(node, old_props, tx_data)
          indexer = find_by_class(old_props['_classname'] || node.class.to_s)
          indexer && indexer.remove_index_on_fields(node, old_props, tx_data)
        end

        def on_property_changed(node, field, old_val, new_val)
          classname = node['_classname'] || node.class.to_s
          indexer = find_by_class(classname)
          indexer && indexer.update_index_on(node, field, old_val, new_val)
        end

        def on_rel_property_changed(rel, field, old_val, new_val)
          # works exactly like for nodes
          on_property_changed(rel, field, old_val, new_val)
        end

        def on_relationship_created(rel)
          on_node_created(rel)
        end

        def on_relationship_deleted(rel, old_props, tx_data)
          on_node_deleted(rel, old_props,tx_data)
        end
      end
    end
    Neo4j.unstarted_db.event_handler.add(IndexerRegistry)

  end
end
