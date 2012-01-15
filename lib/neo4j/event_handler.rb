module Neo4j

  # == Handles Transactional Events
  #
  # You can use this to receive event before the transaction commits.
  # The following events are supported:
  # * <tt>on_neo4j_started</tt>
  # * <tt>on_neo4j_shutdown</tt>
  # * <tt>on_node_created</tt>
  # * <tt>on_node_deleted</tt>
  # * <tt>on_relationship_created</tt>
  # * <tt>on_relationship_deleted</tt>
  # * <tt>on_property_changed</tt>
  # * <tt>on_rel_property_changed</tt>
  # * <tt>on_after_commit</tt>
  #
  # ==== on_neo4j_started(db)
  #
  # Called when the neo4j engine starts.
  # Notice that the neo4j will be started automatically when the first neo4j operation is performed.
  # You can also start Neo4j: <tt>Neo4j.start</tt>
  #
  # * <tt>db</tt> :: the Neo4j::Database instance
  #
  # ==== on_neo4j_shutdown(db)
  #
  # Called when the neo4j engine shutdown. You don't need to call <tt>Neo4j.shutdown</tt> since
  # the it will automatically be shutdown when the application exits (using the at_exit ruby hook).
  #
  # * <tt>db</tt> :: the Neo4j::Database instance
  #
  # ==== on_after_commit(data, state)
  #
  # Called after the transaction has successfully committed.
  # See http://api.neo4j.org/1.4/org/neo4j/graphdb/event/TransactionEventHandler.html for the data and state parameter.
  #
  # ==== on_node_created(node)
  #
  # * <tt>node</tt> :: the node that was created
  #
  # ==== on_node_deleted(node, old_props, deleted_relationship_set, deleted_node_identity_map)
  #
  # * <tt>node</tt> :: the node that was deleted
  # * <tt>old_props</tt> :: a hash of the old properties this node had
  # * <tt>deleted_relationship_set</tt> :: the set of deleted relationships. See Neo4j::RelationshipSet
  # * <tt>deleted_node_identity_map</tt> :: the identity map of deleted nodes. The key is the node id, and the value is the node
  #
  # ==== on_relationship_created(rel, created_node_identity_map)
  #
  # * <tt>rel</tt> :: the relationship that was created
  # * <tt>created_node_identity_map</tt> :: the identity map of created nodes. The key is the node id, and the value is the node
  #
  # ==== on_relationship_deleted(rel, old_props, deleted_relationship_set, deleted_node_identity_map)
  #
  # * <tt>rel</tt> :: the relationship that was created
  # * <tt>old_props</tt> :: a hash of the old properties this relationship had
  # * <tt>deleted_relationship_set</tt> :: the set of deleted relationships. See Neo4j::RelationshipSet
  # * <tt>deleted_node_identity_map</tt> :: the identity map of deleted nodes. The key is the node id, and the value is the node
  #
  # ==== on_property_changed(node, key, old_value, new_value)
  #
  # * <tt>node</tt> :: the node
  # * <tt>key</tt> :: the name of the property that was changed (String)
  # * <tt>old_value</tt> :: old value of the property
  # * <tt>new_value</tt> :: new value of the property
  #
  # ==== on_rel_property_changed(rel, key, old_value, new_value)
  #
  # * <tt>rel</tt> :: the node that was created
  # * <tt>key</tt> :: the name of the property that was changed (String)
  # * <tt>old_value</tt> :: old value of the property
  # * <tt>new_value</tt> :: new value of the property
  #
  # ==== classes_changed(class_change_map)
  # * <tt>class_change_map</tt> :: a hash with class names as keys, and class changes as values. See Neo4j::ClassChanges
  #
  # == Usage
  #
  #   class MyListener
  #     def on_node_deleted(node, old_props, deleted_relationship_set, deleted_node_identity_map)
  #     end
  #   end
  #
  #   # to add an listener without starting neo4j:
  #   Neo4j.unstarted_db.event_handler.add(MyListener.new)
  #
  # You only need to implement the methods that you need.
  #
  class EventHandler
    include org.neo4j.graphdb.event.TransactionEventHandler

    def initialize
      @listeners = []
    end


    def after_commit(data, state)
      @listeners.each {|li|  li.on_after_commit(data, state) if li.respond_to?(:on_after_commit)}
    end

    def after_rollback(data, state)
    end

    def before_commit(data)
      class_change_map = java.util.HashMap.new
      created_node_identity_map = iterate_created_nodes(data.created_nodes, class_change_map)
      deleted_node_identity_map = deleted_node_identity_map(data.deleted_nodes)
      deleted_relationship_set = relationship_set(data.deleted_relationships)
      removed_node_properties_map = property_map(data.removed_node_properties)
      removed_relationship_properties_map = property_map(data.removed_relationship_properties)
      add_deleted_nodes(data, class_change_map, removed_node_properties_map)
      empty_map = java.util.HashMap.new
      data.assigned_node_properties.each { |tx_data| property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, tx_data.value) unless tx_data.key == '_classname'}
      data.removed_node_properties.each { |tx_data| property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, nil) unless deleted_node_identity_map.containsKey(tx_data.entity.getId) }
      data.deleted_nodes.each { |node| node_deleted(node, removed_node_properties_map.get(node.getId)||empty_map, deleted_relationship_set, deleted_node_identity_map)}
      data.created_relationships.each {|rel| relationship_created(rel, created_node_identity_map)}
      data.deleted_relationships.each {|rel| relationship_deleted(rel, removed_relationship_properties_map.get(rel.getId)||empty_map, deleted_relationship_set, deleted_node_identity_map)}
      data.assigned_relationship_properties.each { |tx_data| rel_property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, tx_data.value) }
      data.removed_relationship_properties.each {|tx_data| rel_property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, nil) unless deleted_relationship_set.contains_rel?(tx_data.entity) }
      classes_changed(class_change_map)
    rescue Exception => e
      # since these exceptions gets swallowed
      puts "ERROR in before commit hook #{e}"
      puts e.backtrace.join("\n")
    end


    def iterate_created_nodes(nodes, class_change_map)
      identity_map = java.util.HashMap.new
      nodes.each do |node|
        identity_map.put(node.neo_id,node) #using put due to a performance regression in JRuby 1.6.4
        instance_created(node, class_change_map)
        node_created(node)
      end
      identity_map
    end

    def deleted_node_identity_map(nodes)
      identity_map = java.util.HashMap.new
      nodes.each{|node| identity_map.put(node.neo_id,node)} #using put due to a performance regression in JRuby 1.6.4
      identity_map
    end

    def relationship_set(relationships)
      relationship_set = Neo4j::RelationshipSet.new#(relationships.size)
      relationships.each{|rel| relationship_set.add(rel)}
      relationship_set
    end

    def property_map(properties)
      map = java.util.HashMap.new
      properties.each do |property|
        map(property.entity.getId, map).put(property.key, property.previously_commited_value)
      end
      map
    end

    def map(key,map)
      map.get(key) || add_map(key,map)
    end

    def add_map(key,map)
      map.put(key, java.util.HashMap.new)
      map.get(key)
    end

    def add(listener)
      @listeners << listener unless @listeners.include?(listener)
    end

    def remove(listener)
      @listeners.delete(listener)
    end

    def remove_all
      @listeners = []
    end

    def print
      puts "Listeners #{@listeners.size}"
      @listeners.each {|li| puts "  Listener '#{li}'"}
    end

    def neo4j_started(db)
      @listeners.each { |li| li.on_neo4j_started(db) if li.respond_to?(:on_neo4j_started) }
    end

    def neo4j_shutdown(db)
      @listeners.each { |li| li.on_neo4j_shutdown(db) if li.respond_to?(:on_neo4j_shutdown) }
    end

    def node_created(node)
      @listeners.each {|li| li.on_node_created(node) if li.respond_to?(:on_node_created)}
    end

    def node_deleted(node,old_properties, deleted_relationship_set, deleted_node_identity_map)
      @listeners.each {|li| li.on_node_deleted(node,old_properties, deleted_relationship_set, deleted_node_identity_map) if li.respond_to?(:on_node_deleted)}
    end

    def relationship_created(relationship, created_node_identity_map)
      @listeners.each {|li| li.on_relationship_created(relationship, created_node_identity_map) if li.respond_to?(:on_relationship_created)}
    end

    def relationship_deleted(relationship, old_props, deleted_relationship_set, deleted_node_identity_map)
      @listeners.each {|li| li.on_relationship_deleted(relationship, old_props, deleted_relationship_set, deleted_node_identity_map) if li.respond_to?(:on_relationship_deleted)}
    end

    def property_changed(node, key, old_value, new_value)
      @listeners.each {|li| li.on_property_changed(node, key, old_value, new_value) if li.respond_to?(:on_property_changed)}
    end

    def rel_property_changed(rel, key, old_value, new_value)
      @listeners.each {|li| li.on_rel_property_changed(rel, key, old_value, new_value) if li.respond_to?(:on_rel_property_changed)}
    end

    def add_deleted_nodes(data, class_change_map, removed_node_properties_map)
      data.deleted_nodes.each{|node| instance_deleted(node, removed_node_properties_map, class_change_map)}
    end

    def instance_created(node, class_change_map)
      classname = node[:_classname]
      class_change(classname, class_change_map).add(node) if classname
    end

    def instance_deleted(node, removed_node_properties_map, class_change_map)
      properties = removed_node_properties_map.get(node.getId)
      if properties
        classname = properties.get("_classname")
        class_change(classname, class_change_map).delete(node) if classname
      end
    end

    def class_change(classname, class_change_map)
      class_change_map.put(classname, ClassChanges.new) if class_change_map.get(classname).nil?
      class_change_map.get(classname)
    end

    def classes_changed(changed_class_map)
      @listeners.each {|li| li.classes_changed(changed_class_map) if li.respond_to?(:classes_changed)}
    end
  end

  class ClassChanges
    attr_accessor :added, :deleted

    def initialize
      self.added = []
      self.deleted = []
    end

    def add(node)
      self.added << node
    end

    def delete(node)
      self.deleted << node
    end

    def net_change
      self.added.size - self.deleted.size
    end
  end
end