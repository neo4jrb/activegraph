module Lucene
  
   
  #
  # Contains the result as a collection of Documents from a lucene query.
  # Is a wrapper for the Java org.apache.lucene.search.Hits class
  # 
  class Hits
    include Enumerable
  
    def initialize(field_infos, hits)
      @hits = hits
      @field_infos = field_infos
    end
  
    
    #
    # Returns the n:th hit document.
    #
    def [](n)
      doc = @hits.doc(n)
      Document.convert(@field_infos, doc)
    end
  
    
    #
    # Returns true if there are no hits
    # 
    def empty?
      @hits.length == 0
    end
    
    def each
      iter = @hits.iterator
    
      while (iter.hasNext && hit = iter.next)
        yield Document.convert(@field_infos, hit.getDocument)
      end
    end
  
    
    #
    # The number of documents the query gave.
    #
    def size
      @hits.length
    end
    
    def to_s
      "Hits [size=#{size}]"
    end
    
  end
end