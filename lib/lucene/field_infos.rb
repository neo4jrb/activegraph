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
      $LUCENE_LOGGER.debug{"FieldInfos create new FieldInfo key '#{key}'"} if @infos[key].nil?
      @infos[key] ||= DEFAULTS.dup
      @infos[key]
    end
    
    def []=(key,value)
      case value
      when Hash : @infos[key] = FieldInfo.new(value)
      when FieldInfo : @infos[key] = value
      else raise ArgumentError.new("only accept Hash and FieldInfo, got #{value.class.to_s}")
      end
    end
  end
end