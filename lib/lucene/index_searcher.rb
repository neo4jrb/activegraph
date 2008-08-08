require 'lucene/jars'
require 'lucene/query_dsl'

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

    def find_dsl(field_infos,&block)
      exp = QueryDSL.parse(&block)  
      query = exp.to_lucene(field_infos)
      
      Hits.new(field_infos, index_searcher.search(query))      
    end
    
    
    def find(field_infos, fields)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless exist?
      
      query = BooleanQuery.new
      
      fields.each_pair do |key,value|
        field = field_infos[key]
        q = field.convert_to_query(key, value)
        query.add(q, BooleanClause::Occur::MUST)
      end

      Hits.new(field_infos, index_searcher.search(query))
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