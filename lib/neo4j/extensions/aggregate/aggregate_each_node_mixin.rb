module Neo4j::Aggregate

  module AggregateEachNodeMixin
    include Neo4j::NodeMixin
    include Enumerable

    has_list :groups, :counter => true #, :cascade_delete => :incoming
    attr_reader :aggregate_id

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

    def aggregate_each(nodes_or_class)
      @aggregator = AggregatorEach.new(self, nodes_or_class)
    end
  end

end
