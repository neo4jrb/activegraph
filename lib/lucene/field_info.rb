require 'date'

module Lucene
  class ConversionNotSupportedException < StandardError; end

  class FieldInfo 
    DEFAULTS = {:store => false, :type => String, :analyzer => :standard}.freeze
    
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
      # convert the ruby value to a string that lucene can handle
      cvalue = convert_to_lucene(value)

      # check if this field should be indexed 
      return nil if cvalue.nil?

      # decide if the field should be stored in the lucene index or not
      store = store? ? org.apache.lucene.document.Field::Store::YES : org.apache.lucene.document.Field::Store::NO

      # decide if it should be tokenized/analyzed by lucene
      token_type = tokenized? ? org.apache.lucene.document.Field::Index::ANALYZED : org.apache.lucene.document.Field::Index::NOT_ANALYZED
      $LUCENE_LOGGER.debug{"java_field store=#{store} key='#{key.to_s}' value='#{cvalue}' token_type=#{token_type}"}

      # create the new Field
      org.apache.lucene.document.Field.new(key.to_s, cvalue, store, token_type ) #org.apache.lucene.document.Field::Index::NO_NORMS)
    end

    
    def convert_to_ruby(value)
      if (value.kind_of?(Array))
        value.collect{|v| convert_to_ruby(v)}
      else case @info[:type].to_s
        when NilClass.to_s then  ""  # TODO, should we accept nil values in indexes ?
        when String.to_s then value.to_s
        when Fixnum.to_s then  value.to_i
        when Float.to_s  then  value.to_f
        when Date.to_s
          return value if value.kind_of? Date
          return nil if value.nil?
          year = value[0..3].to_i
          month = value[4..5].to_i
          day = value[6..7].to_i
          Date.new year,month,day
        when DateTime.to_s
          return value if value.kind_of? DateTime
          return nil if value.nil?
          year = value[0..3].to_i
          month = value[4..5].to_i
          day = value[6..7].to_i
          hour = value[8..9].to_i
          min = value[10..11].to_i
          sec = value[12..13].to_i
          DateTime.civil(year,month,day,hour,min,sec)
        else
          raise ConversionNotSupportedException.new("Can't convert key '#{value}' of with type '#{@info[:type].class.to_s}'")
        end
      end
    end

    def convert_to_lucene(value)
      if (value.kind_of?(Array))
        value.collect{|v| convert_to_lucene(v)}
      elsif value.nil?
        value
      else
        case @info[:type].to_s # otherwise it will match Class
        when Fixnum.to_s then  sprintf('%011d',value)     # TODO: configurable
        when Float.to_s  then  sprintf('%024.12f', value)  # TODO: configurable
        when Bignum.to_s then  sprintf('%024d, value')
        when Date.to_s
          t = Time.utc(value.year, value.month, value.day)
          d = t.to_i * 1000
          org.apache.lucene.document.DateTools.timeToString(d,org.apache.lucene.document.DateTools::Resolution::DAY )
        when DateTime.to_s
          # only utc times are supported 
          t = Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)
          d = t.to_i * 1000
          org.apache.lucene.document.DateTools.timeToString(d,org.apache.lucene.document.DateTools::Resolution::SECOND )
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
      infos = @info.keys.inject(""){|s, key| s << "#{key}=#{@info[key]} "}
      "FieldInfo(#{self.object_id.to_s}) [#{infos}]"
    end
    
    
  end
end

