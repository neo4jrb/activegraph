module Neo4j::Aggregate

  # Aggregates properties on one or more nodes.
  # Can also be used to apply functions (e.g. sum/average) on a set of properties.
  #
  module PropsAggregateMixin
    include Neo4j::NodeMixin
    include Enumerable

    has_list :groups, :counter => true #, :cascade_delete => :incoming

    def init_node(*args)
      @aggregate_id = args[0] unless args.empty?
    end
    
    def aggregate_size
      @aggregator.execute if @aggregator
      groups.size
    end
    
    def each
      @aggregator.execute if @aggregator
      groups.each {|sub_group| sub_group.each {|val| yield val}}
    end

    def aggregate(agg_id)
      @aggregator = PropsAggregator.new(self, agg_id.to_s)
    end
  end

end
