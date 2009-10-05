module Neo4j::Aggregate

  module AggregateEachNodeMixin
    include Neo4j::NodeMixin
    include Enumerable

    has_list :groups, :counter => true

    def aggregate_size
      groups.size
    end
    
    def each
      groups.each {|node| yield node}
    end

    def aggregate_each(nodes)
      AggregatorEach.new(self, nodes)
    end
  end

end
