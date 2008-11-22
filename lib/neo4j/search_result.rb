module Neo4j
  class SearchResult
    include Enumerable
    
    def initialize(hits)
      @hits = hits # lucene hits
    end
    
    def each
      Transaction.run do
        @hits.each do |doc|
          id = doc[:id]
          node = Neo4j.instance.find_node(id.to_i)
          # can happen that another thread has deleted it
          raise LuceneIndexOutOfSyncException.new("lucene found node #{id} but it does not exist in neo") if node.nil?
          yield node
        end
      end
    end
    
    def [](n)
      doc = @hits[n]
      Transaction.run do
        id = doc[:id]
        Neo4j.instance.find_node(id.to_i)
      end      
    end
    
    
    def size
      @hits.size
    end
  end
end

  
#            hits.collect do |doc|
#            id = doc[:id]
#            node = Neo4j.instance.find_node(id.to_i)
#            raise LuceneIndexOutOfSyncException.new("lucene found node #{id} but it does not exist in neo") if node.nil?
#            node
#          end
