require 'lucene/field_info'

module Lucene
  
  #
  # A collection of FieldInfo objects. Also contains the name of the id field.
  # Fields has default value FieldInfos::DEFAULTS.
  # 
  class FieldInfos 
    DEFAULTS = FieldInfo.new({}).freeze
    
    attr_reader :id_field 
  
    def initialize(id_field, infos = {})
      @id_field = id_field
      @infos = infos
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
