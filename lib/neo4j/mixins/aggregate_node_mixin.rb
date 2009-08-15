module Neo4j

  # By including this mixin you can create one or more aggregation node groups for your own node.
  #
  module AggregateNodeMixin

    # Creates aggregated nodes by grouping nodes by one or more property values.
    # Raises an exception if the aggregation already exists.
    # 
    # ==== Parameters
    #  aggregate_id:: the id of this aggregate. The class using this mixin may contain several different aggregations.
    #
    # ==== Returns
    # an object that has the following methods
    # * with(an enumeration) - specifies which nodes it should aggregate into groups of nodes
    # * group_by(*keys) - specifies which property or properties values it should group by
    # * group_each_by - same as group_by but instead of creating a unique group for all nodes it creates new groups for each given node.
    # * execute - executes the aggregation, creates new nodes that groups the specified nodes
    #
    # ==== Example - use the mixin
    #
    #   class MyAggregatedNode
    #      include Neo4j::NodeMixin
    #      include Neo4j::AggregateNodeMixin
    #   end
    #
    # ==== Example - group by one property
    #
    # Let say we have nodes with properties :colour and we want to create new nodes for each colour (like a pivot table in a spreadsheet).
    #
    #   a = MyAggregatedNode.new
    #
    #   a.create_aggregate(:colour).with(enumeration of nodes we want to aggregate).group_by(:colour).execute
    #
    # The following node structure will be created:
    #   AggregateNodeMixin --<colour>--> Aggregate_Node --<red/green/blue...>--*> Aggregated Node --<colour>--*>
    #
    # Print all groups, red, green, blue:
    #   a.aggregate(:colour}.each{|n| puts n[:colour]}
    #
    #   a.aggregate(:colour).each {|group| group.aggregate(:red).each {|n| puts n} } # prints all nodes, group by :colour
    #
    #   # which is the same as
    #   a.aggregate(:colour, :red).each {|node| puts node} # only prints nodes with colour property 'red'
    #
    # ==== Example - Aggregating Properties
    #
    # The aggregator also aggregate properties. If a property does not exist on an aggregated node it will traverse all nodes in its group and
    # return an enumeration of its values. This work for both a specific aggregation group (e.g. aggregate node with colour red) as well as with
    # all groups
    #
    # Get an enumeration of names of people having favorite colour 'red'
    #
    #   a.aggregate(:colour, :red)[:name].to_a => ['bertil', 'adam', 'adam']
    #
    # Get an enumeration of all names in all groups
    #
    #   a.aggregate(:colour, :red)[:name].to_a => ['bertil', 'adam', 'adam', 'andreas', ...]
    #
    # ==== Example - group by a property value which is transformed
    #
    #  Group by a age range, 0-4, 5-9, 10-14 etc...
    #
    #   a = MyAggregatedNode.new
    #   a.create_aggregate(:age_groups).with(an enumeration of nodes).group_by(:age).of_value{|age| age / 5}.execute
    #
    #   # traverse all people in age group 10-14   (3 maps to range 10-14)
    #   a.aggregate(:age_group, 3).each {|x| ...}
    #
    #   # traverse all groups
    #   a.aggregate(:age_group).each {|x| ...}
    #
    #   # how many age groups are there ?
    #   a.aggregate(:age_group).size
    #
    #   # how many people are in age group 10-14
    #   a.aggregate(:age_group, 3).size
    #
    #   # which is same as
    #   a.aggregate(:age_group).aggregate(3).size
    #
    # :api: public
    def create_aggregate(aggregate_id)
      raise "aggregation #{aggregate_id} already exists" unless aggregate(aggregate_id).nil?
      agg_node = AggregatorNode.create(aggregate_id)
      relationships.outgoing(aggregate_id) << agg_node
      agg_node
    end

    # Returns an aggregation.
    # See #create_aggregate for usage.
    #
    # :api: public
    def aggregate(aggregate_id, aggregate_group=nil)
      aggregate_node = relationships.outgoing(aggregate_id).nodes.first
      return if aggregate_node.nil?
      return aggregate_node if aggregate_group.nil?
      aggregate_node.aggregate(aggregate_group)
    end
  end

  class AggregateGroupNode
    include Neo4j::NodeMixin
    include Enumerable

    property :aggregate_id, :aggregate_group, :size

    def self.create(aggregate_id, aggregate_group)
      new_node = AggregateGroupNode.new
      new_node.aggregate_id = aggregate_id.to_s
      new_node.aggregate_group = aggregate_group.kind_of?(Symbol)? aggregate_group.to_s : aggregate_group
      new_node.size = 0
      new_node
    end

    def each
      relationships.outgoing.nodes.each { |n| yield n }
    end

    def get_property(key)
      value = super(key)
      return value unless value.nil?
      # traverse all sub nodes and get their properties
      AggregatedProperties.new(relationships.outgoing.nodes, key)
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

  class AggregatorNode
    include Neo4j::NodeMixin
    include Enumerable

    property :aggregate_id, :size

    def self.create(aggregate_id)
      new_node = AggregatorNode.new
      new_node.aggregate_id = aggregate_id.to_s
      new_node.size = 0
      new_node
    end


    def get_property(key)
      value = super(key)
      return value unless value.nil?
      # traverse all sub nodes and get their properties
      AggregatedProperties.new(relationships.outgoing.nodes, key)
    end


    def aggregate(aggregate_group)
      relationships.outgoing(aggregate_group).nodes.first
    end

    def with(nodes)
      @nodes = nodes
      self
    end

    def group_by(*keys)
      @keys = keys
      self
    end

    def group_by_each(*keys)
      # todo
      self
    end
    
    def map_value(&map_func)
      @map_func = map_func
      self
    end


    def each
      relationships.outgoing.nodes.each {|n| yield n}
    end

    # Create a group key for given node
    def group_key_of(node)
      if @map_func.nil?
        @keys.map{|key| node[key]}.join('_')
      else
        args = @keys.map{|key| node[key]}
        raise "Wrong number of argument of map_value function, expected #{args.size} args but it takes #{@map_func.arity} args" if @map_func.arity != args.size
        @map_func.call(*args)
      end
    end


    def execute
      @nodes.each do |node|
        group_key = group_key_of(node)
        group_node = relationships.outgoing(group_key).nodes.first
        if group_node.nil?
          group_node = AggregateGroupNode.create(aggregate_id, group_key)
          relationships.outgoing(group_key) << group_node
          self.size += 1 # another group was created
        end
        group_node.size += 1
        group_node.relationships.outgoing(aggregate_id) << node
      end
    end
  end
end