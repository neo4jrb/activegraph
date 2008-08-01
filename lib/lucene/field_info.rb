module Lucene
  class ConversionNotSupportedException < StandardError; end
  
  class FieldInfo 
    DEFAULTS = {:store => false, :type => String}.freeze 
    TYPE_CONVERSION_TABLE = { Fixnum => :to_i, Float => :to_f, String => :to_s }
    
    def initialize(values)
      @info = DEFAULTS.dup
      @info.merge! values
      $LUCENE_LOGGER.debug{"new FieldInfo: #{@info.inspect}"}
    end

    def dup
      FieldInfo.new(@info)
    end
    
    
    def [](key)
      @info[key]
    end
    
    def []=(key,value)
      @info[key] = value
    end
    
    def java_field(key, value)    
      store = store? ? org.apache.lucene.document.Field::Store::YES : org.apache.lucene.document.Field::Store::NO      
      $LUCENE_LOGGER.debug{"java_field store=#{store} key='#{key.to_s}' value='#{value.to_s}'"}      
      org.apache.lucene.document.Field.new(key.to_s, value.to_s, store, org.apache.lucene.document.Field::Index::UN_TOKENIZED ) #org.apache.lucene.document.Field::Index::NO_NORMS)
    end
    
    def convert_type(value)
      method = TYPE_CONVERSION_TABLE[@info[:type]]
      raise ConversionNotSupportedException.new("Can't convert key '#{key}' since method '#{method}' is missing") unless value.respond_to? method
      value.send(method)
    end
    
    def store?
      @info[:store]
    end

    def eql?(other)
      return false unless other.kind_of?(FieldInfo)
      @info.each_pair do |key,value|
        return false if other[key] != value
      end
      return true
    end
    
    def ==(other)
      eql? other
    end
    
    def to_s
      "FieldInfo [store=#{store?}]"
    end
    
    
  end
end

