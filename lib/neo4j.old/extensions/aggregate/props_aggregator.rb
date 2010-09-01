module Neo4j::Aggregate
  class PropsAggregator
    def initialize(root_node, agg_id)
      @root_node = root_node
      @agg_id = agg_id
    end


    def on(nodes_or_class)
      if (nodes_or_class.kind_of?(Class) and nodes_or_class.ancestors.include?(Neo4j::NodeMixin))
        Neo4j.event_handler.add(self)
        @filter = nodes_or_class
        @nodes = nodes_or_class
      elsif (!nodes_or_class.respond_to?(:each))
        @nodes = [nodes_or_class]
      else
        @nodes = nodes_or_class
      end
      self
    end

    def props(*properties)
      @group_by = properties
      self
    end

    # Unregisters this aggregate so that it will not be notified any longer
    # on Neo4j node events. Used when we create an aggregate that is registered
    # with the Neo4j even listener by including a filter in the aggregate method
    #
    # ==== Example
    # agg_reg = my_aggregate.aggregate_each(MyNode).group_by(:something)
    # # add some MyNodes that my_aggregate will aggregate into groups
    # MyNode.new # etc...
    # # we now do not want to add more nodes using the aggregate above - unregister it
    # agg_reg.unregister
    # # no more nodes will be appended /deleted /modified in the my_aggregate.
    #
    def unregister
      Neo4j.event_handler.remove(self)
    end

    # called from neo4j event handler
    # :api: private
    def on_property_changed(node, prop_key, old_value, new_value) # :nodoc:
      return if node.class != @filter
      return unless @group_by.include?(prop_key.to_sym)

      # recreate the aggregate group
      execute([node])
    end


    def with(prop_key, &proc)
      @with_proc = proc
      @prop_key = prop_key
      self
    end

    def execute(nodes = @nodes)
      return unless nodes
      nodes.each do |node|
        group_node = node.aggregate_groups(@agg_id)
        if group_node.nil?
          group_node = PropGroup.new
          group_node.group_by = @group_by.join(',')
          group_node.aggregate = node
          rel = group_node.rels.outgoing(:aggregate)[node]
          rel[:aggregate_group] = @agg_id
          @root_node.groups << group_node
        end
        if @with_proc
          val = group_node.inject(0) {|sum, val| next sum if val.nil?; @with_proc.call(sum, val, 0)}
          group_node[@prop_key.to_s] = val
        end
      end
      @nodes = nil # prevent it to run twice
    end
  end
end