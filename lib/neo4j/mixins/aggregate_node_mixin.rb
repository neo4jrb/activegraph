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
          yield group.relationships.incoming.nodes.first # there can't be more then one, each group belongs to one aggregate node
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
    def aggregate_groups
      relationships.incoming(:aggregate).nodes
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
  #   a.aggregate(nodes).group_by(:colour).execute
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
  #   a.aggregate(an enumeration of nodes).group_by(:age).of_value{|age| age / 5}.execute
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
  # The group_by method takes one or more property keys which it combines into one group key.
  # Each node that is included in an group_by aggregate will only be member of one aggregate group.
  #
  # By using the group_by_each method instead one node may be member in more then one aggregate group.
  #
  #   node1 = Neo4j::Node.new; node1[:colour] = 'red'; node1[:type] = 'A'
  #   node2 = Neo4j::Node.new; node2[:colour] = 'red'; node2[:type] = 'B'
  #
  #   agg_node = MyAggregateNode.new
  #   agg_node.aggregate([node1, node2]).group_by_each(:colour, :type).execute
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
  # ==== Example - aggregating over another aggregation
  #
  #   a = MyAggregatedNode.new
  #   a.aggregate.group_by(:colour)
  #   a << node1, node2
  #
  #   b = MyAggregatedNode.new
  #   b.aggregate.group_by(:age)
  #   node3[:colour] = 'green'; node3[:age] = 10
  #   node4[:colour] = 'red';   node3[:age] = 11
  #
  #   b << node3 <<node4
  #
  #   a << b
  #
  #   a['green'][10] #=>[node3]
  #
  #
  # ==== Example - Add and remove nodes by events (NOT IMPLEMENTED YET)
  #
  # We want to both create and delete nodes and the aggregates should be updated automatically
  # This is done by registering the aggregate dsl method as an event listener
  #
  # Here is an example that update the aggregate a on all nodes of type MyNode
  #   a = MyAggregatedNode.new
  #   Neo4j.event_handler.add(a.aggregate(nodes).group_by(:colour).filter{|node| node.kind_of? MyNode})
  #
  #   Neo4j::Transaction.run { blue_node = MyNode.new; a.colour = 'blue' }
  #   # then the aggregate will be updated automatically since it listen to property change events
  #   a['blue'].size = 1
  #   a['blue'].to_a[0] # => blue_node
  #
  #   Neo4j::Transaction.run { blue_node.delete }
  #   a['blue'].size = 0
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
    def aggregate(nodes=nil)
      self.aggregate_size ||= 0
      @aggregator = AggregateDSL.new(self, nodes)
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
    # true if it is
    #
    # :api: public
    def include_node?(node)
      key = @aggregator.group_key_of(node)
      group = get_group(key)
      return false if group.nil?
      group.include?(node)
    end


    # Returns the group with the given key
    # If there is no group with that key it returns nil
    #
    # :api: public
    def get_group(key)
      # TODO check kind_of? since it might return the wrong node
      relationships.outgoing(key).nodes.find{|n| n.kind_of? AggregateGroupNode}
    end


    # Overrides the get_property method (which is used by [] operator)
    # Do not use this method, use instead the [] operator.
    #
    # If there is a relationship of the given key, and that node is kind_of?
    # that that relationships point to will be returned (as an Enumeration).
    # Otherwise, return the property of this node.
    #
    def get_property(key)
      group_node = get_group(key)
      return group_node unless group_node.nil?

      super(key)
    end


    def each
      relationships.outgoing.nodes.each {|n| yield n}
    end

  end

  # Used to create a DSL describing how to aggregate an enumeration of nodes
  class AggregateDSL
    def initialize(base_node, nodes)
      @base_node = base_node
      @nodes = nodes
    end

    def group_by(*keys)
      @group_by = keys
      @by_each = false
      self
    end

    def group_by_each(*keys)
      @group_by = keys
      @by_each = true
      self
    end

    def map_value(&map_func)
      @map_func = map_func
      self
    end

    # Create a group key for given node
    def group_key_of(node)
      values = @group_by.map{|key| node[key]}
      if !@map_func.nil?
        raise "Wrong number of argument of map_value function, expected #{values.size} args but it takes #{@map_func.arity} args" if @map_func.arity != values.size
        values = @map_func.call(*values)
        values = [values] unless values.kind_of? Enumerable
      end

      # check all values and expand enumerable values
      values.inject(Set.new) {|result, value| value.respond_to?(:to_a) ? result.merge(value.to_a) : result << value }.to_a
    end

    # Executes the DSL and creates the specified groups.
    def execute(nodes = @nodes)
      nodes.each do |node|
#        execute(node) if node.kind_of?(Enumerable)

        group_key = group_key_of(node)

        # check if it can be added to a group
        next if group_key.nil? || group_key.to_s.empty?

        # if we are not grouping by_each then there will only be one group_key - join it
        group_key = [group_key.join('_')] unless @by_each

        group_key.each do |key|
          group_node = @base_node.relationships.outgoing(key).nodes.first
          if group_node.nil?
            group_node = AggregateGroupNode.create(key)
            rel = @base_node.relationships.outgoing(key) << group_node
            @base_node.aggregate_size += 1 # another group was created
            rel[:aggregate_group] = key
          end
          group_node.aggregate_size += 1
          rel = group_node.relationships.outgoing(:aggregate) << node
          rel[:aggregate_group] = key
        end
      end
    end

  end

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

    def get_property(key)
      super(key)
      value = super(key)
      return value unless value.nil?
      # traverse all sub nodes and get their properties
      AggregatedProperties.new(relationships.outgoing.nodes, key)
    end

    def set_property(key, value)
      super key, value
      val = self.get_property(key)
    end
  end

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