module Neo4j::ActiveNode::Query
  class QueryProxyProxy
    attr_reader :preloader, :query_proxy

    def initialize(original_query_proxy)
      @query_proxy = original_query_proxy
    end

    def method_missing(method_name, *args, &block)
      @query_proxy = query_proxy.send(method_name, *args, &block)
    end
  end
end
