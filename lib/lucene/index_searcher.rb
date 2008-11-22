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
    
    
    def find(field_info, fields)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless exist?
      
      query = case fields
      when String
        parser = org.apache.lucene.queryParser.QueryParser.new(field_info.id_field.to_s, org.apache.lucene.analysis.standard.StandardAnalyzer.new)
        parser.parse(fields)
      when Hash
        query = org.apache.lucene.search.BooleanQuery.new
        fields.each_pair do |key,value|
          field = field_info[key]
          q = field.convert_to_query(key, value)
          query.add(q, org.apache.lucene.search.BooleanClause::Occur::MUST)
        end
        query
      else
        raise StandardError.new("Unknown type #{fields.class.to_s} for find #{fields}")
      end
      Hits.new(field_info, index_searcher.search(query))
      
    end

    #
    # Checks if it needs to reload the index searcher
    #
    def index_searcher
      if @index_reader.nil? || @index_reader.getVersion() != org.apache.lucene.index.IndexReader.getCurrentVersion(@path)
        @index_reader = org.apache.lucene.index.IndexReader.open(@path)        
        @index_searcher = org.apache.lucene.search.IndexSearcher.new(@index_reader)        
        $LUCENE_LOGGER.debug("Opened new IndexSearcher for #{to_s}")         
      end
      @index_searcher
    end
    
    #
    # Returns true if the index already exists.
    #
    def exist?
      org.apache.lucene.index.IndexReader.index_exists(@path)
    end

  end
end
