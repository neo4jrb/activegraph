module Lucene
  class ConversionNotSupportedException < StandardError; end
  
  class FieldInfo 
    DEFAULTS = {:store => false, :type => String}.freeze 
    TYPE_CONVERSION_TABLE = { Fixnum => :to_i, Float => :to_f, String => :to_s }
    
    def initialize(values = {})
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
      cvalue = convert_to_lucene(value)
      token_type = tokenized? ? org.apache.lucene.document.Field::Index::ANALYZED : org.apache.lucene.document.Field::Index::NOT_ANALYZED
      $LUCENE_LOGGER.debug{"java_field store=#{store} key='#{key.to_s}' value='#{cvalue}' type=#{token_type}"}
      org.apache.lucene.document.Field.new(key.to_s, cvalue, store, token_type ) #org.apache.lucene.document.Field::Index::NO_NORMS)
    end
    
    def convert_to_ruby(value)
      method = TYPE_CONVERSION_TABLE[@info[:type]]
      raise ConversionNotSupportedException.new("Can't convert key '#{key}' since method '#{method}' is missing") unless value.respond_to? method
      if (value.kind_of?(Array))       
        value.collect{|v| v.send(method)}
      else
        value.send(method)
      end
    end

    def convert_to_lucene(value)    
      if (value.kind_of?(Array)) 
        value.collect{|v| convert_to_lucene(v)}
      else
        case @info[:type].to_s # otherwise it will match Class
        when Fixnum.to_s then  sprintf('%011d',value)     # TODO: configurable
        when Float.to_s  then  sprintf('%024.12f', value)  # TODO: configurable
        when Bignum.to_s then  sprintf('%024d, value')
        else value.to_s
        end
      end
    end
    
    def convert_to_query(key,value)
      if (value.kind_of? Range)
        first_value = convert_to_lucene(value.first)
        last_value = convert_to_lucene(value.last)
        first = org.apache.lucene.index.Term.new(key.to_s, first_value)        
        last = org.apache.lucene.index.Term.new(key.to_s, last_value)        
        $LUCENE_LOGGER.debug{"convert_to_query: Range key '#{key.to_s}' #{first_value}' to '#{last_value}'"}
        org.apache.lucene.search.RangeQuery.new(first, last, !value.exclude_end?)
      elsif
        converted_value = convert_to_lucene(value)
        term = org.apache.lucene.index.Term.new(key.to_s, converted_value)        
        org.apache.lucene.search.TermQuery.new(term)
#        pq = org.apache.lucene.search.PhraseQuery.new
#        pq.add(term)
#        pq.setSlop 3
#        pq
      end
    end

    def tokenized?
      @info[:tokenized]
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
      s = "FieldInfo(#{self.object_id.to_s})
      @info.each_pair {|key,value| s << "#{key}=#{value} "}
      s + "]"
    end
    
    
  end
end

