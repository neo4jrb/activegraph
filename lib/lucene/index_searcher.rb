require 'lucene/jars'

module Lucene
  
  #
  # Does reuse Lucene Index Search for the same index.
  # Reloads the index if the index has changed.
  #
  class IndexSearcher
    
    @@paths = {}
    
    def initialize(path,field_infos)
      @path = path
      @field_infos = field_infos
    end

    #
    # Only create a new object if it does not already exist for this path    
    #
    def self.new(path,id_field)
      @@paths[path] = super(path,id_field) if @@paths[path].nil?
      @@paths[path]
    end

    def find(fields)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless exist?
      
      query = BooleanQuery.new
      
      fields.each_pair do |key,value|  
        q = if (value.kind_of? Range)
          first = org.apache.lucene.index.Term.new(key.to_s, pad(value.first))        
          last = org.apache.lucene.index.Term.new(key.to_s, pad(value.last))        
          org.apache.lucene.search.RangeQuery.new(first, last, !value.exclude_end?)
        elsif
          term  = org.apache.lucene.index.Term.new(key.to_s, value.to_s)        
          TermQuery.new(term) 
        end
        query.add(q, BooleanClause::Occur::MUST)
      end

      Hits.new(@field_infos, index_searcher.search(query))
      
      #      hits = index_searcher.search(query).iterator
      #      results = []
      #      while (hits.hasNext && hit = hits.next)
      #        id = hit.getDocument.getField("id").stringValue.to_i
      #        results <<  id #[hit.getScore, id, text]
      #      end
      #      results
    end
    
    
    #
    # Checks if it needs to reload the index searcher
    #
    def index_searcher
      if @index_reader.nil? || @index_reader.getVersion() != IndexReader.getCurrentVersion(@path)
        @index_reader = IndexReader.open(@path)        
        @index_searcher = org.apache.lucene.search.IndexSearcher.new(@index_reader)        
        $LUCENE_LOGGER.debug("Opened new IndexSearcher for #{to_s}")         
      end
      @index_searcher
    end
    
    #
    # Returns true if the index already exists.
    #
    def exist?
      IndexReader.index_exists(@path)
    end

  end
end