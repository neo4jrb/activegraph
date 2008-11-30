module Neo4j
  
  # 
  # Holds the search result and performs the query.
  # The query is not performed until a search result item is requested.
  # It is possible that one node is deleted,updated,created after the search is performed.
  #
  class SearchResult
    include Enumerable
    
    def initialize(index, query, &block)
      @query = query
      @block = block
      @index = index
      @sort_by_fields = []
    end

    def hits
      @hits ||=  @index.find(query_params, &@block)
    end

    def query_params
      return @query.merge({:sort_by => @sort_by_fields}) unless @sort_by_fields.empty?
      return @query
    end
    
    def each
      Transaction.run do
        hits.each do |doc|
          id = doc[:id]
          node = Neo4j.instance.find_node(id.to_i)
          # can happen that another thread has deleted it
          raise LuceneIndexOutOfSyncException.new("lucene found node #{id} but it does not exist in neo") if node.nil?
          yield node
        end
      end
    end
    
    def [](n)
      doc = hits[n]
      Transaction.run do
        id = doc[:id]
        Neo4j.instance.find_node(id.to_i)
      end
    end
    
    def sort_by(*fields)
      @sort_by_fields += fields
      self
    end
    
    def size
      hits.size
    end
  end
end
