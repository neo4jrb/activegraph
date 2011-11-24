module Neo4j
  module Index
    class IndexerRegistry #:nodoc:
      class << self

        def delete_all_indexes
          @@indexers.values.each {|i| i.delete_index_type}
        end

        def create_for(this_clazz, using_other_clazz, type)
          @@indexers                  ||= {}
          index                       = Indexer.new(this_clazz, type)
          index.inherit_fields_from(@@indexers[using_other_clazz.to_s]) if @@indexers[using_other_clazz.to_s]
          @@indexers[this_clazz.to_s] = index
        end

        def find_by_class(classname)
          @@indexers[classname]
        end

        def on_node_deleted(node, old_props, deleted_relationship_set, deleted_identity_map)
          indexer = find_by_class(old_props['_classname'] || node.class.to_s)
          indexer && indexer.remove_index_on_fields(node, old_props, deleted_relationship_set)
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

        def on_relationship_created(rel,created_identity_map)
          end_node = rel._end_node
          # if end_node was created in this transaction then it will be handled in on_property_changed
          created = created_identity_map.get(end_node.neo_id)
          unless created
            indexer = find_by_class(end_node['_classname'])
            indexer && indexer.update_on_new_relationship(rel)
          end
        end

        def on_relationship_deleted(rel, old_props, deleted_relationship_set, deleted_identity_map)
          on_node_deleted(rel, old_props, deleted_relationship_set, deleted_identity_map)
          # if only the relationship has been deleted then we have to remove the index
          # if both the relationship and the node has been deleted then the index will be removed in the
          # on_node_deleted callback
          end_node = rel._end_node
          deleted = deleted_identity_map.get(end_node.neo_id)
          unless deleted
            indexer = find_by_class(end_node['_classname'])
            indexer && indexer.update_on_deleted_relationship(rel)
          end
        end

        def on_neo4j_shutdown(*)
          @@indexers.each_value {|indexer| indexer.on_neo4j_shutdown}
        end
      end
    end
    Neo4j.unstarted_db.event_handler.add(IndexerRegistry) unless Neo4j.read_only?
  end
end
