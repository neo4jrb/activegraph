require 'set'

module Neo4j

  module NodeMixin

    # Used for an enumerable result of aggregates
    # See Neo4j::NodeMixin#aggregates
    #
    # :api: private
    class AggregateEnumeration
      include Enumerable

      def initialize(node)
        @node = node
      end

      def each
        @node.relationships.incoming(:aggregate).nodes.each do |group|
          yield group.relationships.incoming.nodes.first
        end
      end
    end



    # Returns an enumeration of aggregates that this nodes belongs to.
    #
    # Is used in combination with the Neo4j::AggregateNodeMixin
    #
    # ==== Example
    #
    #   class MyNode
    #      include Neo4j::NodeMixin
    #      include Neo4j::AggregateNodeMixin
    #   end
    #
    #   agg1 = MyNode
    #   agg1.aggregate(:colours).group_by(:colour)
    #
    #   agg2 = MyNode
    #   agg2.aggregate(:age).group_by(:age)
    #
    #   agg1 << node1
    #   agg2 << node1
    #
    #   node1.aggregates.to_a # => [agg1, agg2]
    #
    def aggregates
      AggregateEnumeration.new(self)
    end

    # Returns an enumeration of groups that this nodes belongs to.
    #
    # Is used in combination with the Neo4j::AggregateNodeMixin
    #
    # ==== Parameters
    #
    # * group which aggregate group we want, default is :all - an enumeration of all groups will be return
    #
    #
    # ==== Returns
    # an enumeration of all groups that this node belongs to, or if the group parameter was used
    # only the given group or nil if not found.
    #
    # ==== Example
    #
    #   class MyNode
    #      include Neo4j::NodeMixin
    #      include Neo4j::AggregateNodeMixin
    #   end
    #
    #   agg1 = MyNode
    #   agg1.aggregate(:colours).group_by(:colour)
    #
    #   agg2 = MyNode
    #   agg2.aggregate(:age).group_by(:age)
    #
    #   agg1 << node1
    #   agg2 << node1
    #
    #   node1.aggregate_groups.to_a # => [agg1[some_group], agg2[some_other_group]]
    #
    def aggregate_groups(group = :all)
      return relationships.incoming(:aggregate).nodes if group == :all
      relationships.incoming(:aggregate).filter{self[:aggregate_group] == group}.nodes.to_a[0]
    end
  end


  # Enables aggregation of an enumeration of nodes into groups.
  # Each group is a neo4j node which contains aggregated properties of the underlying nodes in that group.
  #
  # Notice that the AggregateNodeMixin#aggregate method takes an Ruby Enumeration of neo4j nodes.
  # That means that you can use for example the output from the Neo4j::NodeMixin#traverse as input to the aggregate method, or even
  # create aggregates over aggregates.
  #
  # This mixin includes the Enumerable mixin.
  #
  # ==== Example - use the mixin
  #
  # Example how to create your own class that will provide aggregation of nodes.
  #
  #   class MyAggregatedNode
  #      include Neo4j::NodeMixin
  #      include Neo4j::AggregateNodeMixin
  #   end
  #
  # This class can create group nodes that will be connected as outgoing relationships from it.
  #
  # ==== Example - group by one property
  #
  # Let say we have nodes with properties :colour and we want to group them by colour:
  #
  #   a = MyAggregatedNode.new
  #
  #   a.aggregate(nodes).group_by(:colour)
  #
  # The following node structure will be created:
  #
  #   [node a]--<relationship type red|green|blue...>--*>[node groups]--<relationship type aggregate>--*>[node nodes]
  #
  # Print all three groups, one for each colour
  #
  #   a.each{|n| puts n[:colour]}
  #
  # Print all nodes belonging to one colour group:
  #
  #   a[:red].each {|node| puts node}
  #
  # ==== Example - Aggregating Properties
  #
  # The aggregator also aggregate properties. If a property does not exist on an aggregated group it will traverse all nodes in its group and
  # return an enumeration of its values.
  #
  # Get an enumeration of names of people having favorite colour 'red'
  #
  #   a.[:red][:name].to_a => ['bertil', 'adam', 'adam']
  #
  # ==== Example - group by a property value which is transformed
  #
  #  Let say way want to have group which include a range of values.
  #  Example - group by an age range, 0-4, 5-9, 10-14 etc...
  #
  #   a = MyAggregatedNode.new
  #   a.aggregate(an enumeration of nodes).group_by(:age).of_value{|age| age / 5}
  #
  #   # traverse all people in age group 10-14   (3 maps to range 10-14)
  #   a[3].each {|x| ...}
  #
  #   # traverse all groups
  #   a.each {|x| ...}
  #
  #   # how many age groups are there ?
  #   a.aggregate_size
  #
  #   # how many people are in age group 10-14
  #   a[3].aggregate_size
  #
  # ==== Example - Group by several properties
  #
  # The group_by method takes one or more property keys which it combines into one or more groups.
  #
  #   node1 = Neo4j::Node.new; node1[:colour] = 'red'; node1[:type] = 'A'
  #   node2 = Neo4j::Node.new; node2[:colour] = 'red'; node2[:type] = 'B'
  #
  #   agg_node = MyAggregateNode.new
  #   agg_node.aggregate([node1, node2]).group_by(:colour, :type)
  #
  #   # node1 is member of two groups, red and A
  #   node1.aggregate_groups.to_a # => [agg_node[:red], agg_node[:A]]
  #
  #   # group A contains node1
  #   agg_node[:A].include?(node1) # => true
  #
  #   # group red also contains node1
  #   agg_node[:red].include?(node1) # => true
  #
  # ==== Example - Appending new nodes to aggregates
  #
  # The aggregate node mixin implements the << operator that allows you to append nodes to the aggregate and the
  # appended node will be put in the correct group.
  #
  #   a = MyAggregatedNode.new
  #   a.aggregate.group_by(:age).of_value{|age| age / 5}
  #
  #   a << node1 << node2
  #
  # Notice that we do not need call the execute method. That method will be called each time we append nodes to the aggregate.
  #
  # ==== Example - trees of aggregates
  #
  # One example where this is needed is for having a tree structure of nodes with latitude and longitude grouped by a 'zoom' factor
  #
  # create an aggrgeation of groups where members have the same latitude longitude integer values (to_i)
  #   reg1 = agg_root.aggregate().group_by(:latitude, :longitude).map_value{|lat, lng| "#{(lat*1000).to_i}_#{(lng*1000).to_i}"}
  #
  # create another aggregation of groups where members have the same latitude longitude 1/10 value
  #   reg2 = agg_root.aggregate(reg1).group_by(:latitude, :longitude).map_value{|lat, lng| "#{(lat*100).to_i}_#{(lng*100).to_i" }
  #
  # Notice how the second aggreate uses the first aggregate (reg1). This will create the following structure with
  # * node n1 - (latitude 42.1234 and longitude 12.1234) and
  # * node n2 (latitude 42.1299 and longitude 12.1298)
  # * node n3 (latitude 42.1333 and longitude 12.1298)
  #
  #                      Root agg_root
  #                        |       |
  #            Group 4212_1212   Group  4213_1212
  #                  |                  |
  #          Group 42123_12123   Group 42133_12129
  #             |    |                  |
  #            n1   n2                 n3
  #
  # When the nodes n1,n2,n3 are added to the agg_root, e.g:
  #   agg_root << n1 << n2 << n3
  #
  # ==== Example - aggregating over another aggregation
  #
  #   a = MyAggregatedNode.new
  #   a.aggregate.group_by(:colour)
  #   a << node1 << node2
  #
  #   b = MyAggregatedNode.new
  #   b.aggregate.group_by(:age)
  #   node3[:colour] = 'green'; node3[:age] = 10
  #   node4[:colour] = 'red';   node3[:age] = 11
  #
  #   b << node3 << node4
  #
  #   a << b
  #
  #   a['green'][10] #=>[node3]
  #
  #
  # ==== Example - Add and remove nodes by events
  #
  # We want to both create and delete nodes and the aggregates should be updated automatically
  # This is done by registering the aggregate dsl method as an event listener
  #
  # Here is an example that update the aggregate a on all nodes of type MyNode
  #   a = MyAggregatedNode.new
  #
  #   # the aggreate will get notified when nodes of type MyNode get changed
  #   a.aggregate(MyNode).group_by(:colour)
  #
  #   Neo4j::Transaction.run { blue_node = MyNode.new; a.colour = 'blue' }
  #   # then the aggregate will be updated automatically since it listen to property change events
  #   a['blue'].size = 1
  #   a['blue'].to_a[0] # => blue_node
  #
  #   blue_node[:colour] = 'red'
  #   a['blue']     # => nil
  #   a['red'].to_a # => [blue_node]  
  #   blue_node.delete
  #   a['red']      # => nil
  #
  module AggregateNodeMixin
    include Neo4j::NodeMixin
    property :aggregate_size  # number of groups this aggregate contains
    include Enumerable



    # Creates aggregated nodes by grouping nodes by one or more property values.
    # Raises an exception if the aggregation already exists.
    # 
    # ==== Parameters
    # * aggregate(optional an enumeration) - specifies which nodes it should aggregate into groups of nodes
    #
    #  If the no argument is given for the aggregate method then nodes can be appended to the aggregate using the << method.
    #
    # ==== Returns
    # an object that has the following methods
    # * group_by(*keys) - specifies which property or properties values it should group by
    # * group_each_by - same as group_by but instead of combinding the properties it creates new groups for each given property
    # * execute - executes the aggregation, creates new nodes that groups the specified nodes
    #
    # :api: public
    def aggregate(nodes_or_filter=nil)
      # setting a property here using neo4j.rb might trigger events which we do not want
      internal_node.set_property("aggregate_size", 0) unless internal_node.has_property("aggregate_size")
      @aggregator = AggregateDSL.new(self, nodes_or_filter)
    end

    # Appends one or a whole enumeration of nodes to the existing aggregation.
    # Each node will be put into aggregate groups that was specified using the aggregate method.
    #
    # If the node does not have a property(ies) used for grouping nodes then the node will node be appendend to the aggreation.
    # Example:
    #   my_agg.aggregate.group_by(:colour)
    #   my_agg << Neo4j::Node.new # this node will not be added since it is missing the colour property
    #
    # ==== Parameter
    # * node(an enumeration, or one node) - specifies which node(s) should be appneit should aggregate into groups of nodes
    #
    # ==== Returns
    # self
    #
    def <<(node)
#      @aggregator.execute if @aggregator
      if node.kind_of?(Enumerable)
        @aggregator.execute(node)
      else
        @aggregator.execute([node])
      end
      self
    end


    # Checks if the given node is include in this aggregate
    #
    # ==== Returns
    # true if the aggregate includes the given node.
    #
    # :api: public
    def include_node?(node)
      key = @aggregator.group_key_of(node)
      group = group_node(key)
      return false if group.nil?
      group.include?(node)
    end

    # Returns the group with the given key
    # If there is no group with that key it returns nil
    #
    # :api: public
    def group_node(key)
      @aggregator.execute if @aggregator
      relationships.outgoing(key).nodes.find{|n| n.kind_of? AggregateGroupNode}
    end


    # Overrides the get_property method (which is used by [] operator)
    # Do not use this method, use instead the [] operator.
    #
    # If there is a relationship of the given key, and that node is kind_of?
    # that that relationships point to will be returned (as an Enumeration).
    # Otherwise, return the property of this node.
    #
    # :api: private
    def get_property(key)
      node = group_node(key)
      return node unless node.nil?

      super(key)
    end


    def each
      @aggregator.execute if @aggregator
      relationships.outgoing.nodes.each {|n| yield n if n.kind_of? AggregateGroupNode}
    end

  end

  # Used to create a DSL describing how to aggregate an enumeration of nodes
  #
  # :api: public
  class AggregateDSL
    attr_accessor :root_dsl

    def initialize(root_node, dsl_nodes_or_filter)
      @root_node = root_node
      self.root_dsl = self #if not chained dsl then the root dsl is self

      if dsl_nodes_or_filter.kind_of?(AggregateDSL)
        # we are chaining aggregates
        @child_dsl = dsl_nodes_or_filter
        @child_dsl.root_dsl = self  # the child has a pointer to the parent (todo parent or root ?)
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


    # Unregisters this aggregate so that it will not be nofitied any longer
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
      "AggregateDSL group_by #{@group_by} filter #{!@filter.nil?} object_id: #{self.object_id} child: #{!@child_dsl.nil?}"
    end


    def on_node_deleted(node)
      return if node.class != @filter
      props = node.props
      # create a property hash with property keys and property nil values - all values are deleted 
      del_node = (props.keys - ['classname', 'id']).inject ({}){ |result, key| result.merge({key=> nil})}
      root_dsl.on_changed(node, del_node, node)
    end

    def on_property_changed(node, prop_key, old_value, new_value)
      return if node.class != @filter
      return unless @group_by.include?(prop_key.to_sym)
      old_node = node.props
      old_node[prop_key] = old_value
      root_dsl.on_changed(node, node, old_node)
    end

    def on_changed(node, curr_node_values, old_node_values)
      old_group_keys = group_key_of(old_node_values)
      new_group_keys = group_key_of(curr_node_values)

      # keys that are removed
      removed = old_group_keys - new_group_keys

      # find all incoming relationships with those names and delete them
      removed.each do |key|
        member_of = node.relationships.incoming(:aggregate).filter{self[:aggregate_group] == key}.to_a
        raise "same group key used in several aggregate groups, strange #{member_of.size}" if member_of.size > 1
        next if member_of.empty?
        group_node = member_of[0].start_node
        group_node.aggregate_size -= 1
        member_of[0].delete

        # should we delete the whole group
        if (group_node.aggregate_size == 0)
          # get the aggregate
          group_node.relationships.incoming(key).nodes.each do |agg|
            agg[:aggregate_size] -= 1
          end
          group_node.delete
        end
      end
      # keys that are added
      added = new_group_keys - old_group_keys
      root = self.root_dsl
      root ||= self
      added.each { |key| root.create_group_for_key(@root_node, node, key) }
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
      group_keys = values.inject(Set.new) {|result, value| value.respond_to?(:to_a) ? result.merge(value.to_a) : result << value }.to_a

      # if we are not grouping by_each then there will only be one group_key - join it
      group_keys = [group_keys] unless group_keys.respond_to?(:each)
      group_keys
    end

    # Executes the DSL and creates the specified groups.
    # This method is not neccessarly to call, since it will automatically be called when needed.
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
      group_node =  parent.relationships.outgoing(key).nodes.find{|n| n.kind_of? AggregateGroupNode}

      # if no group key is found create a new one
      group_node ||= create_group_node(parent, key)

      # check if it is the leaf node or not
      if (@child_dsl)
        # this is not the leaf aggregate dsl, let the child node add the node instaed
        @child_dsl.create_groups(group_node, node)  # TODO
      else
        # this IS a leaf aggregate dsl, add node to the group
        rel_type = node.kind_of?(AggregateGroupNode)? key : :aggregate
        rel = group_node.relationships.outgoing(rel_type) << node
        rel[:aggregate_group] = key
        # increase the size counter on this group
        group_node.aggregate_size += 1
      end
    end

    # :api: private
    def create_group_node(parent, key)
      new_node = AggregateGroupNode.create(key)
      rel = parent.relationships.outgoing(key) << new_node
      parent.aggregate_size += 1 # another group was created
      rel[:aggregate_group] = key
      new_node
    end

  end


  # This is the group node. When a new aggregate group is created it will be of this type.
  # Includes the Enumerable mixin in order to iterator over each node member in the group.
  # Overrides [] and []= properties, so that we can access aggregated properties or relationships.
  #
  # :api: private
  class AggregateGroupNode
    include Neo4j::NodeMixin
    include Enumerable

    property :aggregate_group, :aggregate_size

    def self.create(aggregate_group)
      new_node = AggregateGroupNode.new
      new_node.aggregate_group = aggregate_group.kind_of?(Symbol)? aggregate_group.to_s : aggregate_group
      new_node.aggregate_size = 0
      new_node
    end

    def each
      relationships.outgoing.nodes.each { |n| yield n }
    end

    # :api: private
    def get_property(key)
      value = super(key)
      return value unless value.nil?

      sub_group = relationships.outgoing(key).nodes.first
      return sub_group unless sub_group.nil?

      # traverse all sub nodes and get their properties
      AggregatedProperties.new(relationships.outgoing.nodes, key)
    end

    def set_property(key, value)
      super key, value
      val = self.get_property(key)
    end
  end


  # Used to aggregate property values.
  #
  # :api: private
  class AggregatedProperties
    include Enumerable

    def initialize(nodes, property)
      @nodes = nodes
      @property = property
    end

    def each
      @nodes.each do |n|
        v = n[@property]
        if v.kind_of?(Enumerable)
          v.each {|vv| yield vv}
        else
          yield v
        end
      end

    end

  end
end