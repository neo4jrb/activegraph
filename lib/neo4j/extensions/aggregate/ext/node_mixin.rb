org.neo4j.kernel.impl.core.RelationshipProxy.class_eval do
  include Neo4j::JavaPropertyMixin

    def end_node  # duplicated code, needed for node_aggregate_spec - JRuby bug ?
      id = getEndNode.getId
      Neo4j.load_node(id)
    end

    def start_node # duplicated code, needed for node_aggregate_spec - JRuby bug ?
      id = getStartNode.getId
      Neo4j.load_node(id)
    end

    def other_node(node) # duplicated code, needed for node_aggregate_spec - JRuby bug ?
      neo_node = node
      neo_node = node._java_node if node.respond_to?(:_java_node)
      id = getOtherNode(neo_node).getId
      Neo4j.load_node(id)
    end
  
end


org.neo4j.kernel.impl.core.NodeProxy.class_eval do

  # Returns an enumeration of aggregates that this nodes belongs to.
  #
  # Is used in combination with the Neo4j::AggregateNodeMixin
  #
  # ==== Example
  #
  #   class MyNode
  #      include Neo4j::NodeMixin
  #      include Neo4j::NodeAggregateMixin
  #   end
  #
  #   agg1 = MyNode
  #   agg1.aggregate([node1,node2]).group_by(:colour)
  #
  #   agg2 = MyNode
  #   agg2.aggregate([node1,node2]).group_by(:age)
  #
  #   [*node1.aggregates] # => [agg1, agg2]
  #
  def aggregates
    Neo4j::Aggregate::AggregateEnum.new(self)
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
  #   [*node1.aggregate_groups] # => [agg1[some_group], agg2[some_other_group]]
  #
  def aggregate_groups(group = :all)
    return rels.incoming(:aggregate).nodes if group == :all
    [*rels.incoming(:aggregate).filter{self[:aggregate_group] == group.to_s}.nodes][0]
  end

end


module Neo4j
  module NodeMixin
   def_delegators :@_java_node, :aggregate_groups, :aggregates
  end
end
