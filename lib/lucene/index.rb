require 'delegate'
require 'lucene/jars'

#
# A wrapper for the Java lucene search library.
#
module Lucene
  

  # 
  # Represents a Lucene Index.
  # The index is written/updated only when the commit method is called.
  # This is done since writing to the index file should be done as a batch operation.
  # (Performace will be bad otherwise).
  #  
  class Index
    # TODO thread synchronization
    
    def initialize(path)
      @path = path # where the index is stored on disk
      @documents = {}
      @deleted_ids = []
    end
    
    def update(doc)
      @documents[doc.id.value] = doc
    end
    
    def delete(id)
      @deleted_ids << id.to_s
    end
    
    def updated?(id)
      @documents[id.to_s]
    end
    
    def self.instance(path)
      # TODO: THREAD safty
      @instances ||= {}
      @instances[path] = Index.new(path) unless has_index(path)
      @instances[path]
    end
    
    def self.remove_instance(path)
      @instances ||= {}
      @instances.delete(path) unless has_index(path)
    end
    
    def self.has_index(path)
      return false unless @instances
      return @instances[path] != nil
    end
    
    # 
    # Writes to the index files
    # Open and closes an lucene IndexWriter
    #
    def commit
      delete_documents # deletes all docuements given @deleted_ids
      
      # are any updated document deleted ?
      deleted_ids = @documents.keys & @deleted_ids
      # delete them those
      deleted_ids.each {|id| @documents.delete(id)}
      
      # update the remaining documents that has not been deleted
      update_documents # update @documents
    ensure
      @documents.clear
      @deleted_ids.clear
    end

    #
    # Returns true if the index already exists.
    #
    def exist?
      IndexReader.index_exists(@path)
    end
    
    
    def find(fields)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless exist?
      
      query = BooleanQuery.new
      
      fields.each_pair do |key,value|  
        term  = org.apache.lucene.index.Term.new(key.to_s, value.to_s)        
        q = TermQuery.new(term)
        query.add(q, BooleanClause::Occur::MUST)
      end

      engine = IndexSearcher.new(@path)
      hits = engine.search(query).iterator
      results = []
      while (hits.hasNext && hit = hits.next)
        id = hit.getDocument.getField("id").stringValue.to_i
        results <<  id #[hit.getScore, id, text]
      end
      results
    ensure
      engine.close unless engine.nil?
    end
    
    def to_s
      "Index [path: '#@path', #{@documents.size} documents]"
    end
    
    #
    # -------------------------------------------------------------------------
    # Private methods
    #
    
    private 
    
    def update_documents
      index_writer = IndexWriter.new(@path, StandardAnalyzer.new, ! exist?)
      @documents.each_value do |doc|
        # removes the document and adds it
        index_writer.updateDocument(doc.id.to_java_term, doc.to_java)
      end
    ensure
      # TODO exception handling, what if ...
      index_writer.close
    end

    private 
    
    def delete_documents
      return unless exist? # if no index exists then there is nothing to do
      
      writer = IndexWriter.new(@path, StandardAnalyzer.new, false)
      @deleted_ids.each do |id|
        writer.deleteDocuments(Term.new("id", id.to_s))
      end
    ensure
      # TODO exception handling, what if ...
      writer.close unless writer.nil?
    end
    

  end
  
  class Document < DelegateClass(Array)
    
    attr_reader :id  # the field id
    
    def initialize(id)
      super([]) # initialize with an empty array of fields
      @id = Field.new('id', id.to_s, true)
    end
    
    def to_java
      doc   =   org.apache.lucene.document.Document.new
      doc.add(@id.to_java) # want to store the key
      each {|field| doc.add(field.to_java)}
      doc
    end
    
    def to_s
      "Document [id '#{@id.key}', #{size} fields]"
    end
  end
  
  class Field
    attr_reader :key, :value 
    
    def initialize(key, value, store = false)
      @key = key
      @value = value
      @store = store ? org.apache.lucene.document.Field::Store::YES : org.apache.lucene.document.Field::Store::NO
    end
    
    def to_java_term
      org.apache.lucene.index.Term.new(@key, @value)
    end
    
    
    def to_java
      org.apache.lucene.document.Field.new(@key, @value, @store, org.apache.lucene.document.Field::Index::NO_NORMS)
    end

    
    def to_s
      "Field [key='#{@key}', value='#{@value}', store=#{@store}]"
    end
  end
  
end


