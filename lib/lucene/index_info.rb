require 'lucene/field_info'

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
  class IndexInfo 
    DEFAULTS = FieldInfo.new({}).freeze
    
    attr_reader :id_field, :storage, :infos

    def initialize(id_field, storage=nil)
      @id_field = id_field.to_sym
      @infos = {}
      @storage = storage
      # always store the id field
      @infos[@id_field] = FieldInfo.new(:store => true)
    end

    def to_s
      "IndexInfo [#{@id_field}, #{@infos.inspect}]"
    end

    def self.instance?(path)
      return false if @instances.nil?
      ! @instances[path].nil?
    end

    def self.instance(path)
      raise StandardError.new("No StorageInfo has been created for path '#{path}' yet") unless @instances[path]
      $LUCENE_LOGGER.debug{"IndexInfos#instance(#{path}) : ret #{@instances[path]}"}      
      @instances[path]
    end
    
    def self.new_instance(path, id_field, store_on_file)
      $LUCENE_LOGGER.debug{"IndexInfos#new_instance '#{path}'"}
      @instances ||= {}
      storage = path
      storage = org.apache.lucene.store.RAMDirectory.new  unless store_on_file
      @instances[path] = IndexInfo.new(id_field, storage)
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
      org.apache.lucene.index.IndexReader.index_exists(@storage)
    end
    
    def each_pair
      @infos.each_pair{|key,value| yield key,value}
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
