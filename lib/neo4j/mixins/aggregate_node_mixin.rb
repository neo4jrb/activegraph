module Neo4j

  module AggregateNodeMixin

    # Create aggregated nodes for each unique group of nodes. Those aggregated nodes will be connected with unique relationship
    # to this node and each given node.
    #
    #   This node that included the AggregateNodeMixin ---*> Unique Aggregated Nodes ---*> nodes (given)
    #
    # ==== Parameters
    # nodes<Enumeration>:: the nodes that should be aggregated (could be created by Neo4j::NodeMixin#traverse)
    #
    # ==== Example
    #
    #   class AgeGroupAggregateNode
    #      include Neo4j::NodeMixin
    #      include Neo4j::AggregateNodeMixin
    #   end
    #
    #
    #   # I want to put people who knows me of depth 4 into age group 0-4, 5-9, 10-15 etc.. (weird example)
    #   a = AgeGroupAggregateNode.new
    #   a.aggregate(me.traverse.incoming(:friends).depth(4)).with_key(:age_group).of_unique_value{self[:age]/5}.execute
    #
    #   # traverse all people in age group 10-14
    #   a.traverse_aggregate(:age_group, 3).to_a.
    #
    #   # how many people of age 10-14 knows me ?
    #   a.traverse_aggregate(:age_group, 3).to_a.
    #
    # :api: public
    #
    def aggregate(nodes)
      Aggregator.new(self, nodes)
    end

    def traverse_aggregate(key, value)
      return if relationships.outgoing(value).empty?
      sub_aggregate = relationships.outgoing(value).nodes.first
      sub_aggregate.relationships.outgoing(value).nodes
    end

    def count(key, value)
      return 0 if relationships.outgoing(value).empty?
      relationships.outgoing(value).nodes.first[count_key(key)]
    end

    def count_key(key)
      "count_#{key}".to_sym
    end

  end

  class Aggregator
    def initialize(aggregate_node, nodes)
      @aggregate_node = aggregate_node
      @nodes = nodes
    end

    def with_key(key)
      @key = key.to_sym
      self
    end

    def of_unique_value(&block)
      @identity_proc = block
      self
    end

    def count_key
      @aggregate_node.count_key(@key)
    end
    
    def execute
      @nodes.each do |node|
        value = node.instance_eval(&@identity_proc)
        sub_aggregate = @aggregate_node.relationships.outgoing(value).nodes.first
        if sub_aggregate.nil?
          sub_aggregate = Neo4j::Node.new
          sub_aggregate[@key] = value
          @aggregate_node.relationships.outgoing(value) << sub_aggregate
          sub_aggregate[count_key] = 0
        end

        sub_aggregate[count_key] += 1
        sub_aggregate.relationships.outgoing(value) << node
      end
    end
  end
end