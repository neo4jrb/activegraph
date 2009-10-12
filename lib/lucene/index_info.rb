module Lucene
  
  #
  # Contains info for a specific Index identified by a path
  # Contains a 
  # * collection of FieldInfo objects. 
  # * the name of the id field.
  # * the index storage, either file based or RAM based.
  # 
  # Fields has default value IndexInfo::DEFAULTS.
  # 
  class IndexInfo #:nodoc: 
    DEFAULTS = FieldInfo.new({}).freeze
    
    attr_reader :infos, :path
    attr_accessor :id_field
    attr_writer :store_on_file

    # Initializes this object by setting values to default values specified in the Lucene::Config.
    # The path/id to the index is specified by the the path parameter.
    # If the index is Lucene::Config[:storage_path]
    # ==== Block parameters
    # path<String>:: The id or the (incomplete) path on the filesystem of the index
    #
    # :api: private
    def initialize(path)
      $LUCENE_LOGGER.debug{"IndexInfo#initialize(#{path})"}
      @id_field = Lucene::Config[:id_field].to_sym
      @path = path
      @store_on_file = Lucene::Config[:store_on_file]
      @infos = {}
      # always store the id field
      @infos[@id_field] = FieldInfo.new(:store => true)
    end

    def to_s
      "IndexInfo [#{@id_field}, #{@infos.inspect}]"
    end

    def store_on_file?
      @store_on_file
    end
    
    def storage
      @storage ||= create_storage
    end

    def create_storage
      if store_on_file?
        raise StandardError.new("Lucene::Config[:storage_path] is nil but index configured to be stored on filesystem") if Lucene::Config[:storage_path].nil?
        Lucene::Config[:storage_path] + @path
      else
        org.apache.lucene.store.RAMDirectory.new
      end
    end

    
    def self.instance?(path)
      return false if @instances.nil?
      ! @instances[path].nil?
    end

    # Creates and initializes an IndexInfo object by setting values to default
    # values specified in the Lucene::Config. Does not create new object if it has
    # already been created before with the given path.
    # 
    # If the index is stored on the filesystem the complete path will be
    # Lucene::Config[:storage_path] + /path
    # 
    # ==== Block parameters
    # path<String>:: The id or the (incomplete) path on the filesystem of the index
    #
    # :api: public
    def self.instance(path)
      @instances ||= {}
      $LUCENE_LOGGER.debug{"IndexInfos#instance(#{path}) : @instances[path]: #{@instances[path]}"}
      @instances[path] ||= IndexInfo.new(path)
    end
    
    def self.delete_all
      $LUCENE_LOGGER.debug{"IndexInfos#delete_all"}
      @instances = nil
    end
    
    def self.index_exists(path)
      return false if @instances[path].nil?
      instance(path).index_exists?
    end
    
    def index_exists?
      org.apache.lucene.index.IndexReader.index_exists(storage)
    end
    
    def each_pair
      @infos.each_pair{|key,value| yield key,value}
    end

    def analyzer
      # do all fields have the default value :standard analyzer ?
      if @infos.values.find {|info| info[:analyzer] != :standard}
        # no, one or more has set
        wrapper = org.apache.lucene.analysis.PerFieldAnalyzerWrapper.new(org.apache.lucene.analysis.standard.StandardAnalyzer.new)
        @infos.each_pair do |key,value|
          case value[:analyzer]
            when :keyword
              wrapper.addAnalyzer(key.to_s, org.apache.lucene.analysis.KeywordAnalyzer.new)
            when :standard
              # default
            when :simple
              wrapper.addAnalyzer(key.to_s, org.apache.lucene.analysis.SimpleAnalyzer.new)
            when :whitespace
              wrapper.addAnalyzer(key.to_s, org.apache.lucene.analysis.WhitespaceAnalyzer.new)
            when :stop
              wrapper.addAnalyzer(key.to_s, org.apache.lucene.analysis.StopAnalyzer.new)
            else
              raise "Unknown analyzer, supports :keyword, :standard, :simple, :stop, :whitspace, got '#{value}' for field '#{key}'"
          end
        end
        wrapper
      else
        # yes, all fields has standard analyzer
        org.apache.lucene.analysis.standard.StandardAnalyzer.new
      end
    end

    # Returns true if it has one or more tokenized fields
    def tokenized?
      @infos.values.find{|field_info| field_info.tokenized?}
    end

    def [](key)
      k = key.to_sym
      $LUCENE_LOGGER.debug{"FieldInfos create new FieldInfo key '#{k}'"} if @infos[k].nil?
      @infos[k] ||= DEFAULTS.dup
      @infos[k]
    end
    
    def []=(key,value)
      case value
      when Hash then @infos[key] = FieldInfo.new(value)
      when FieldInfo then @infos[key] = value
      else raise ArgumentError.new("only accept Hash and FieldInfo, got #{value.class.to_s}")
      end
    end
  end
end
