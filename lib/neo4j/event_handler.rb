module Neo4j

  # Handles events like a new node is created or deleted
  class EventHandler
    include org.neo4j.graphdb.event.TransactionEventHandler

    def initialize
      @listeners = []
    end


    def after_commit(data, state)
    end

    def after_rollback(data, state)
    end

    def before_commit(data)
      data.created_nodes.each{|node| node_created(node)}
      data.assigned_node_properties.each { |tx_data| property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, tx_data.value) }
      data.removed_node_properties.each { |tx_data| property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, nil) unless data.deleted_nodes.include?(tx_data.entity) }
      data.deleted_nodes.each { |node| node_deleted(node, deleted_properties_for(node,data), data)}
      data.created_relationships.each {|rel| relationship_created(rel)}
      data.deleted_relationships.each {|rel| relationship_deleted(rel, deleted_rel_properties_for(rel, data), data)}
      data.assigned_relationship_properties.each { |tx_data| rel_property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, tx_data.value) }
      data.removed_relationship_properties.each {|tx_data| rel_property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, nil) unless data.deleted_relationships.include?(tx_data.entity) }
    end

    def deleted_properties_for(node, data)
      data.removed_node_properties.find_all{|tx_data| tx_data.entity == node}.inject({}) do |memo, tx_data|
        memo[tx_data.key] = tx_data.previously_commited_value
        memo
      end
    end

    def deleted_rel_properties_for(rel, data)
      data.removed_relationship_properties.find_all{|tx_data| tx_data.entity == rel}.inject({}) do |memo, tx_data|
        memo[tx_data.key] = tx_data.previously_commited_value
        memo
      end
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
      @listeners.each_key {|li| puts "  Listener '#{li}'"}
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

    def node_deleted(node,old_properties, data)
      @listeners.each {|li| li.on_node_deleted(node,old_properties, data) if li.respond_to?(:on_node_deleted)}
    end

    def relationship_created(relationship)
      @listeners.each {|li| li.on_relationship_created(relationship) if li.respond_to?(:on_relationship_created)}
    end

    def relationship_deleted(relationship, old_props, data)
      @listeners.each {|li| li.on_relationship_deleted(relationship, old_props, data) if li.respond_to?(:on_relationship_deleted)}
    end

    def property_changed(node, key, old_value, new_value)
      @listeners.each {|li| li.on_property_changed(node, key, old_value, new_value) if li.respond_to?(:on_property_changed)}
    end

    def rel_property_changed(rel, key, old_value, new_value)
      @listeners.each {|li| li.on_rel_property_changed(rel, key, old_value, new_value) if li.respond_to?(:on_rel_property_changed)}
    end

    # TODO ?
    def tx_finished(tx)
      @listeners.each {|li| li.on_tx_finished(tx) if li.respond_to?(:on_tx_finished)}
    end

    def neo_started(neo_instance)
      @listeners.each {|li|  li.on_neo_started(neo_instance)  if li.respond_to?(:on_neo_started)}
    end

    def neo_stopped(neo_instance)
      @listeners.each {|li| li.on_neo_stopped(neo_instance) if li.respond_to?(:on_neo_stopped)}
    end
  end
end
