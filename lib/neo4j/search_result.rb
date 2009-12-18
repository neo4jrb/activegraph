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
      @hits ||= @index.find(query_params, &@block)
    end

    def query_params
      unless @sort_by_fields.empty?
        return case @query
          when Hash
            @query.merge({:sort_by => @sort_by_fields})
          when String
            [@query, { :sort_by => @sort_by_fields}]
        end
      end
      return @query
    end


    # Returns the first item in the search result
    #
    # :api: public
    def first
      return nil if empty?
      self[0]
    end

    def empty?
      size == 0
    end

    def each
      hits.each do |doc|
        node = Neo4j.load_node(doc[:id])
        # can happen that another thread has deleted it
        raise "lucene found node #{id} but it does not exist in neo" if node.nil?
        yield node
      end
    end

    def [](n)
      doc = hits[n]
      Neo4j.load_node(doc[:id])
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
