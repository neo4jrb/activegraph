require 'lucene/field_info'

module Lucene
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