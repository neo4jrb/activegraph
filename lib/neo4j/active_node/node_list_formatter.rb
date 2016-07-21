module Neo4j::ActiveNode
  class NodeListFormatter
    def initialize(list, max_elements = 5)
      @list = list
      @max_elements = max_elements
    end

    def inspect
      return @list.inspect if !@max_elements || @list.length <= @max_elements
      "[#{@list.take(5).map!(&:inspect).join(', ')}, ...]"
    end
  end
end
