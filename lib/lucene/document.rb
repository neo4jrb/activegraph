module Lucene
  
  #
  # A document is like a record or row in a relation database.
  # Contains the field infos which can be used for type conversions or
  # specifying if the field should be stored or only searchable.
  # 
  class Document
    
    attr_reader :id_field, :field_infos, :props
    
    def initialize(field_infos, props = {})
      @id_field = field_infos.id_field
      @field_infos = field_infos

      @props = {}
      props.each_pair do |key,value|
        @props[key] = field_infos[key].convert_to_ruby(value)
        $LUCENE_LOGGER.debug{"FieldInfo #{key} type: #{field_infos[key][:type]}"}
        $LUCENE_LOGGER.debug{"Converted #{key} '#{value}' type: '#{value.class.to_s}' to '#{@props[key]}' type: '#{@props[key].class.to_s}'"}
      end
    end

    def [](key)
      @props[key]
    end
    
    #
    # Convert a java Document to a ruby Lucene::Document
    #
    def self.convert(field_infos, java_doc)
      fields = {}
      field_infos.each_pair do |key, field|
        next unless field.store?
        raise StandardError.new("expected field '#{key.to_s}' to exist in document") if java_doc.getField(key.to_s).nil?
        value = java_doc.getField(key.to_s).stringValue
        fields.merge!({key => value})
      end
      Document.new(field_infos, fields)
    end

    def id
      raise IdFieldMissingException.new("Missing id field: '#{@id_field}'") if self[@id_field].nil?
      @props[@id_field]      
    end

    def eql?(other)
      return false unless other.is_a? Document
      return id == other.id
    end

    def ==(other)
      eql?(other)
    end
    
    def hash
      id.hash
    end
    
    #
    # removes the document and adds it again
    #
    def update(index_writer)
      index_writer.updateDocument(java_key_term, java_document)
    end
    
    
    def java_key_term
      org.apache.lucene.index.Term.new(@id_field.to_s, id.to_s)
    end
    
    def java_document
      java_doc   =   org.apache.lucene.document.Document.new
      @props.each_pair do |key,value|
        field_info = @field_infos[key]
        # TODO value could be an array if value.kind_of? Enumerable
        if (value.kind_of?(Array))
          value.each do |v|
            field = field_info.java_field(key,v)
            java_doc.add(field) unless field.nil?
          end
        else
          field = field_info.java_field(key,value)
          java_doc.add(field) unless field.nil?
        end
      end
      java_doc
    end
    
    def to_s
      p = ""
      @props.each_pair { |key,value| p << "'#{key}' = '#{value}' " }
      "Document [#@id_field='#{self[@id_field]}', #{p}]"
    end
  end
end
