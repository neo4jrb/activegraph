module Lucene

  class Asc
    class << self

      # Specifies which fields should be sorted in ascending order
      #
      # ==== Parameters
      # fields<Array>:: One or more fields to sort in ascending order
      #
      # ==== Examples
      # Asc[:name, :age]
      #
      # ==== Returns
      # An array of sort fields
      #
      # :api: public
      def [](*fields)
        fields.map{|x| org.apache.lucene.search.SortField.new(x.to_s)}
      end
    end
  end

  class Desc
    class << self
      # Specifies which fields should be sorted in descending order
      #
      # ==== Block parameters
      # fields<Array>:: One or more fields to sort in descending order
      #
      # ==== Examples
      # Desc[:name, :age]
      #
      # ==== Returns
      # An array of sort fields
      #
      # :api: public
      def [](*fields)
        fields.map{|x| org.apache.lucene.search.SortField.new(x.to_s, true)}
        #org.apache.lucene.search.Sort.new(values.map{|x| org.apache.lucene.search.SortField.new(x.to_s, true)}.to_java(:'org.apache.lucene.search.SortField'))
      end
    end
  end

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
    
    
    def find(field_info, query)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless exist?
      
      #puts "QUERY #{query.inspect}" # '#{query.first.class.to_s}' value #{query.first}"
      sort_by ||= query[1].delete(:sort_by) if query[1].kind_of?(Hash)
      sort_by ||= query.delete(:sort_by)
      #puts "QUERY sort #{sort_by}"
      # TODO Refactoring ! too long and complex method
      lucene_query = case query
      when Array
        parser = org.apache.lucene.queryParser.QueryParser.new(field_info.id_field.to_s, org.apache.lucene.analysis.standard.StandardAnalyzer.new)
        parser.parse(query.first)
      when Hash
        bquery = org.apache.lucene.search.BooleanQuery.new
        query.each_pair do |key,value|
          field = field_info[key]
          q = field.convert_to_query(key, value)
          bquery.add(q, org.apache.lucene.search.BooleanClause::Occur::MUST)
        end
        bquery
      else
        raise StandardError.new("Unknown type #{query.class.to_s} for find #{query}")
      end
      
      if sort_by.nil?
        Hits.new(field_info, index_searcher.search(lucene_query))
      else
        sort = create_sort(sort_by) 
        Hits.new(field_info, index_searcher.search(lucene_query, sort))
      end
      
    end

    def parse_field(field)
      case field
      when String,Symbol
        [org.apache.lucene.search.SortField.new(field.to_s)]
      when org.apache.lucene.search.SortField
        [field]
      when Array
        raise StandardError.new("Unknown sort field '#{field}'") unless field.first.kind_of?(org.apache.lucene.search.SortField)
        field
      end
    end


    def create_sort(fields)
      case fields
      when String,Symbol
        org.apache.lucene.search.Sort.new(fields.to_s)
      when org.apache.lucene.search.SortField
        org.apache.lucene.search.Sort.new(fields)
      when Array
        sorts = []
        fields.each do |field|
          sorts += parse_field(field)
        end
        org.apache.lucene.search.Sort.new(sorts.to_java(:'org.apache.lucene.search.SortField')) 
      else
        StandardError.new("Unknown type #{fields.class.to_s}")
      end
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
