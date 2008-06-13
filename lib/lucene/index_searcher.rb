require 'lucene/jars'

module Lucene
  
  #
  # Does reuse Lucene Index Search for the same index.
  # Reloads the index if the index has changed.
  #
  class IndexSearcher
    
    @@paths = {}
    
    def initialize(path)
      @path = path
    end

    #
    # Only create a new object if it does not already exist for this path    
    #
    def self.new(path)
      @@paths[path] = super(path) if @@paths[path].nil?
      @@paths[path]
    end

    def find(fields)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless exist?
      
      query = BooleanQuery.new
      
      fields.each_pair do |key,value|  
        term  = org.apache.lucene.index.Term.new(key.to_s, value.to_s)        
        q = TermQuery.new(term)
        query.add(q, BooleanClause::Occur::MUST)
      end

      hits = index_searcher.search(query).iterator
      results = []
      while (hits.hasNext && hit = hits.next)
        id = hit.getDocument.getField("id").stringValue.to_i
        results <<  id #[hit.getScore, id, text]
      end
      results
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