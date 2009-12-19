module Neo4j::Aggregate
# Used to create a DSL describing how to aggregate an enumeration of nodes
#
# :api: public
  class NodeAggregator
    attr_accessor :root_dsl

    def initialize(root_node, dsl_nodes_or_filter)
      @root_node = root_node
      self.root_dsl = self #if not chained dsl then the root dsl is self

      if dsl_nodes_or_filter.kind_of?(self.class)
        # we are chaining aggregates
        @child_dsl = dsl_nodes_or_filter
        @child_dsl.root_dsl = self # the child has a pointer to the parent
      elsif dsl_nodes_or_filter.kind_of?(Enumerable)
        # we are aggregating an enumerable set of nodes
        @nodes = dsl_nodes_or_filter
      elsif (dsl_nodes_or_filter.kind_of?(Class) and dsl_nodes_or_filter.ancestors.include?(Neo4j::NodeMixin))
        # We are listening for events on Neo4j nodes - that will be included in the aggregates
        @filter = dsl_nodes_or_filter
        # Register with the Neo4j event handler
        Neo4j.event_handler.add(self)
      end

    end


    # Unregisters this aggregate so that it will not be notified any longer
    # on Neo4j node events. Used when we create an aggregate that is registered
    # with the Neo4j even listener by including a filter in the aggregate method
    #
    # ==== Example
    # agg_reg = my_aggregate.aggregate(MyNode).group_by(:something)
    # # add some MyNodes that my_aggregate will aggregate into groups
    # MyNode.new # etc...
    # # we now do not want to add more nodes using the aggregate above - unregister it
    # agg_reg.unregister
    # # no more nodes will be appended /deleted /modified in the my_aggregate.
    #
    def unregister
      Neo4j.event_handler.remove(self)
    end

    def to_s
      "Aggregator group_by #{@group_by} filter #{!@filter.nil?} object_id: #{self.object_id} child: #{!@child_dsl.nil?}"
    end


    # called from neo4j event handler
    # :api: private
    def on_property_changed(node, prop_key, old_value, new_value) # :nodoc:
      return if node.class != @filter
      return unless @group_by.include?(prop_key.to_sym)
      old_node = node.props
      old_node[prop_key] = old_value
      root_dsl.on_prop_added(node, node, old_node)
      on_prop_deleted(node, node, old_node)
    end

    # called from neo4j event handler
    # :api: private
    def on_node_deleted(node) # :nodoc:
      return if node.class != @filter
#      node.print(:incoming, 2)
      node.rels.incoming(:aggregate).filter{start_node.property? :aggregate_size}.each do |group_rel|
        group_node = group_rel.start_node
        group_node.aggregate_size -= 1
        # should we delete the whole group ?
        delete_group(group_node) if (group_node.aggregate_size == 0)
      end
    end

    def delete_group(group_node) # :nodoc:
      # get parent aggregates and decrease the aggregate size
      group_node.rels.incoming.nodes.each do |parent_group|
        next unless parent_group.respond_to? :aggregate_size
        parent_group[:aggregate_size] -= 1
        delete_group(parent_group) if parent_group[:aggregate_size] == 0
      end
      group_node.del
    end


    def on_prop_deleted(node, curr_node_values, old_node_values) # :nodoc:
      old_group_keys = group_key_of(old_node_values)
      new_group_keys = group_key_of(curr_node_values)

      # keys that are removed
      removed = old_group_keys - new_group_keys

      removed.each do |key|
        member_of = [*node.rels.incoming(:aggregate).filter{self[:aggregate_group] == key}]
        raise "same group key used in several aggregate groups, strange #{member_of.size}" if member_of.size > 1
        next if member_of.empty?
        group_node = member_of[0].start_node
        group_node.aggregate_size -= 1
        member_of[0].delete

        # should we delete the whole group
        delete_group(group_node) if (group_node.aggregate_size == 0)
      end

    end

    def on_prop_added(node, curr_node_values, old_node_values) # :nodoc:
      old_group_keys = group_key_of(old_node_values)
      new_group_keys = group_key_of(curr_node_values)

      # keys that are added
      added = new_group_keys - old_group_keys
      added.each { |key| root_dsl.create_group_for_key(@root_node, node, key) }
    end


    # Specifies which properties we should group on.
    # All thos properties can be combined to create a new group.
    #
    # :api: public
    def group_by(*keys)
      @group_by = keys
      self
    end


    # Maps the values of the given properties (in group_by or group_by_each).
    # If this method is not used the group name will be the same as the property value.
    #
    # :api: public
    def map_value(&map_func)
      @map_func = map_func
      self
    end

    # Create a group key for given node
    # :api: private
    def group_key_of(node)
      values = @group_by.map{|key| node[key.to_s]}

      # are there any keys ?
      return [] if values.to_s.empty?

      # should we map the values ?
      if !@map_func.nil?
        raise "Wrong number of argument of map_value function, expected #{values.size} args but it takes #{@map_func.arity} args" if @map_func.arity != values.size
        values = @map_func.call(*values)
        values = [values] unless values.kind_of? Enumerable
      end


      # check all values and expand enumerable values
      group_keys = [*values.inject(Set.new) do |result, value| 
        if value.respond_to?(:to_a) 
          result.merge([*value]) 
        else
          result << value 
        end
      end]

      # if we are not grouping by_each then there will only be one group_key - join it
      group_keys = [group_keys] unless group_keys.respond_to?(:each)
      group_keys
    end

    # Executes the DSL and creates the specified groups.
    # This method is not necessary to call, since it will automatically be called when needed.
    #
    # :api: public
    def execute(nodes = @nodes)
      return if nodes.nil?

      # prevent execute to execute again with the same nodes
      @nodes = nil

      nodes.each { |node| root_dsl.create_groups(@root_node, node) }
    end

    # :api: private
    def create_groups(parent, node)
      group_key_of(node).each { |key| create_group_for_key(parent, node, key) }
    end

    # :api: private
    def create_group_for_key(parent, node, key)
      # find a group node for the given key
      group_node = parent.rels.outgoing(key).nodes.find{|n| n.kind_of? NodeGroup}

      # if no group key is found create a new one
      group_node ||= create_group_node(parent, key)

      # check if it is the leaf node or not
      if (@child_dsl)
        # this is not the leaf aggregate dsl, let the child node add the node instead
        @child_dsl.create_groups(group_node, node)
      else
        # this IS a leaf aggregate dsl, add node to the group
        rel_type = node.kind_of?(NodeGroup)? key : :aggregate
        rel = group_node.add_rel(rel_type, node)
        rel[:aggregate_group] = key
        # increase the size counter on this group
        group_node.aggregate_size += 1
      end
    end

    # :api: private
    def create_group_node(parent, key)
      new_node = NodeGroup.create(key)
      rel = parent.add_rel(key, new_node)
      parent.aggregate_size += 1 # another group was created
      rel[:aggregate_group] = key
      new_node
    end

  end

end