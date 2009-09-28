module Neo4j::Aggregate
  class AggregatorEach
    def initialize(root_node, nodes)
      @root_node = root_node
      @nodes = nodes
    end

    # Specifies which properties we should group on.
    # All thos properties can be combined to create a new group.
    #
    # :api: public
    def group_by(*keys)
      @group_by = keys
      self
    end


    def execute
      @nodes.each do |node|
        puts "agg #{node}"
        group_node = GroupEachNode.new
        group_node.group_by = @group_by.join(',')
        group_node.aggregate = node
        @root_node.groups << group_node
        puts "agg #{node} done"
      end
    end
  end
end