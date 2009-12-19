module Neo4j::Aggregate



  # Enables aggregation of nodes into groups.
  # An aggregation is a node which in contains group nodes.
  # A group node aggregates the properties of the nodes that belongs to its group.
  #
  # There are two ways of creating an aggregate.
  # * Providing an enumeration of nodes.
  # * Register a Node class. All nodes of this class will (can)  be part of the aggregate.
  #
  # One example of usage of providing an enumeration of nodes is by taking the output from
  # the Neo4j::NodeMixin#traverse as input to the aggregate method, or even
  # create aggregates over aggregates.
  #
  # This mixin includes the Enumerable mixin.
  #
  # There is also a different aggregation which aggregates on properties
  # instead of nodes - Neo4j::Aggregate::PropsAggregateMixin
  #
  # ==== Example - group by one property
  #
  # Let say we have nodes with properties :colour and we want to group them by colour:
  #
  #   a = AggregateNode.new
  #
  #   a.aggregate(nodes).group_by(:colour).execute
  #
  # The execute method is only needed when providing nodes (instead of a NodeClass) for the aggregate method.
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
  #   [*a[:red][:name]] => ['bertil', 'adam', 'adam']
  #
  # ==== Example - group by a property value which is transformed
  #
  #  Let say way want to have group which include a range of values.
  #  Example - group by an age range, 0-4, 5-9, 10-14 etc...
  #
  #   a = AggregateNode.new
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
  #   [*node1.aggregate_groups] # => [agg_node[:red], agg_node[:A]]
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
  #   a = AggregateNode.new
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
  # create an aggregation of groups where members have the same latitude longitude integer values (to_i)
  #   reg1 = agg_root.aggregate().group_by(:latitude, :longitude).map_value{|lat, lng| "#{(lat*1000).to_i}_#{(lng*1000).to_i}"}
  #
  # create another aggregation of groups where members have the same latitude longitude 1/10 value
  #   reg2 = agg_root.aggregate(reg1).group_by(:latitude, :longitude).map_value{|lat, lng| "#{(lat*100).to_i}_#{(lng*100).to_i" }
  #
  # Notice how the second aggregate uses the first aggregate (reg1). This will create the following structure with
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
  #
  # ==== Example - Add and remove nodes by events
  #
  # We want to both create and delete nodes and the aggregates should be updated automatically
  # This is done by providing a NodeClass for the aggregate method.
  # (it registering the aggregate dsl method as an event listener
  #
  # Here is an example that update the aggregate a on all nodes of type MyNode
  #   a = AggregateNode.new
  #
  #   # the aggreate will get notified when nodes of type MyNode get changed
  #   a.aggregate(MyNode).group_by(:colour)
  #
  #   Neo4j::Transaction.run { blue_node = MyNode.new; a.colour = 'blue' }
  #   # then the aggregate will be updated automatically since it listen to property change events
  #   a['blue'].size = 1
  #   [*a['blue']][0] # => blue_node
  #
  #   blue_node[:colour] = 'red'
  #   a['blue']     # => nil
  #   [*a['red']] # => [blue_node]
  #   blue_node.delete
  #   a['red']      # => nil
  #
  #
  # ===== TODO Only Aggregate ???
  #
  # a.aggregate([n1,n2])
  # [*a] => [n1, n2]
  #
  # OR without aggregate method
  # a << n1 << n2
  #
  # ===== Example Group by Each  (1)
  #
  #  class MyRoot
  #    include AggregateEach
  #  end
  #
  #  a = MyRoot.new
  #
  #  n1 = [jan=>1, feb=>5, mars=>2, apr=>10, ...]
  #  n2 = [jan=>2, feb=>0, mars=>2, apr=>10, ...]
  #
  #  a.aggregate_each([n1,n2]).group(:jan,:feb,:mars).by(:q1)
  #  [*a[:q1]] = [g1,g2]
  #  g1.props => [n1.neo_id, jan=>1, feb=>5, ..., dec=>]
  #  [*g1] => [1,5,2]
  #
  # ===== Example Group by Each  (2)
  #
  #  n1 = [:colour => 'red',  :age => 10]
  #  n2 = [:colour => 'blue', :age => 11]
  #  n3 = [:colour => 'red',  :age => 12]
  #
  #  a.aggregate_each([n1,n2,n3]).group_by(:colour, :age)
  #  n1.aggregate_groups = [g1]
  #  [*g1] = ['red', 10]
  #  [*a] => [g1,g2,g3]
  #
  #  [*g2] = ['blue', 11]
  #  g1.props => [
  #
  #
  # ===== Example Group by new property
  #
  #  q1.aggregate_each(nodes).group_by(:jan,:feb,:mars)
  #  q2.aggregate_each(nodes).group_by(:apr,:may,:june)
  #
  #
  #                                               T O D O -  G R O U P _ B Y the only needed one (not group and by)
  #  n1 = [jan=>1, feb=>5, mars=>2, apr=>10, ...]
  #  n2 = [jan=>2, feb=>0, mars=>2, apr=>10, ...]
  #
  #  [*q1] => [g1,g2]
  #  [*g1] => [1,5,2]
  #  [*g2] => [2,0,2]
  #
  #  [*q2] => [g3,g4]
  #  n1.aggregate_groups = [g1,g2]
  #  n1[:q1] => nil OR [1,5,2] ????
  #  a[:q1]  => [1,5,2,2,0,2]
  #  n1.each {|n| n[:q1]}
  #
  #  SUM
  #  a.aggregate([n1,n2]).group(:jan,:feb,:mars).by(:q1).sum
  #  n1[:q1] => 8
  #  a[:q1]  => 12
  #
  #
  #  m1 = [revenue => 1000]
  #  m2 = [revenue => 500]
  #  m3 = [revenue => 2000]
  #  a2.aggregate([m1,m2,m3]).group(:revenue).by(:rev).map_value{|v| v >= 1000 ? "good" : "bad"}.count
  #
  #  a[:rev] => ["good", "good", "bad"]
  #  a[:rev]["good"] => 2
  #  a[:rev]["bad"] => 1
  module NodeAggregateMixin
    include Neo4j::NodeMixin
    include Enumerable


    # The number of groups that this aggregate contains
    def aggregate_size
      _java_node.set_property("aggregate_size", 0) unless _java_node.has_property("aggregate_size")
      self[:aggregate_size]
    end


    # Internal method - set the number of groups that this node contains
    # We can then use this property instead of traversing and counting each node in order to find out how many groups there are. 
    def aggregate_size=(value) # :nodoc:
      self[:aggregate_size] = value
    end
    
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
      @aggregator = NodeAggregator.new(self, nodes_or_filter)
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
      rels.outgoing(key).nodes.find{|n| n.kind_of? NodeGroup}
    end


    # Overrides the [] method
    #
    # If there is a relationship of the given key, and that node is kind_of?
    # that that relationships point to will be returned (as an Enumeration).
    # Otherwise, return the property of this node.
    #
    def [](key)
      node = group_node(key)
      return node unless node.nil?
      super(key)
    end


    def each
      @aggregator.execute if @aggregator
      rels.outgoing.nodes.each {|n| yield n if n.kind_of? NodeGroup}
    end

  end



end