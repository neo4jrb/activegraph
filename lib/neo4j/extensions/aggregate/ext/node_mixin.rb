org.neo4j.impl.core.NodeProxy.class_eval do

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
