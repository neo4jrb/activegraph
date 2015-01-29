module Neo4j
  module ActiveNode
    module Query
      class QueryProxyFilteredPreloader < QueryProxyPreloader

        def method_missing(method_name, *args, &block)
          caller.send(method_name, *args, &block)
        end
      end
    end
  end
end
