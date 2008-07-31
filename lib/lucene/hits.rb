module Lucene
  

  # A wrapper for the Java org.apache.lucene.search.Hits class
  class Hits
    include Enumerable
  
    def initialize(field_infos, hits)
      @hits = hits
      @field_infos = field_infos
    end
  
    def [](n)
      doc = @hits.doc(n)
      Document.convert(@field_infos, doc)
    end
  
    def each
      iter = @hits.iterator
    
      while (iter.hasNext && hit = iter.next)
        yield Document.convert(@field_infos, hit.getDocument)
      end
    end
  
    
    def size
      @hits.length
    end
    
    def to_s
      "Hits [size=#{size}]"
    end
    
    #
    # Private
    #    
    private
    
  end
end