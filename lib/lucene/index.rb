require 'delegate'
require 'monitor'
require 'lucene/jars'
require 'lucene/transaction'
require 'lucene/index_searcher'

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
    attr_reader :path 
    
     
    # locks per index path, must not write to the same index from 2 threads 
    @@locks = {}    
    @@locks.extend MonitorMixin
    
    def initialize(path)
      @path = path # where the index is stored on disk
      @documents = {}  # documents to be updated
      @deleted_ids = [] # documents to be deleted
    end

    #
    # Tries to reuse an Index instance for the current running transaction.
    # 
    # If a Lucene::Transaction is running it will register this index in that transaction if
    # this has not already been done.
    # When it has been registered in the transaction the transaction will commit the index 
    # when the transaction is commited.
    #
    def self.new(path)
      # create a new transaction if needed      
      Transaction.new unless Transaction.running?

      # create a new instance only if it does not already exist in the current transaction
      unless Transaction.current.index?(path)
        instance = super(path) 
        Transaction.current.register_index(instance) 
      end

      # return the index for the current transaction
      Transaction.current.index(path)
    end

    #
    # Updates the specified document.
    # The index file not be updated until the transaction commits.
    # The doc is stored in memory till the transaction commits.
    #
    def update(doc)
      @documents[doc.id.value] = doc
    end
    
    #
    # Delete the specified document.
    # Precondition: a Lucene::Transaction must be running.
    # The index file not be updated until the transaction commits.
    # The doc is stored in memory till the transaction commits.
    #
    def delete(id)
      @deleted_ids << id.to_s
    end
    
    def updated?(id)
      @documents[id.to_s]
    end
    
    # 
    # 
    # Writes to the index files
    # Open and closes an lucene IndexWriter
    # Close the IndexSearcher so that it will read the updated index next time.
    # This method will automatically be called from a Lucene::Transaction if it was running when the index was created.
    #
    def commit
      lock.synchronize do
        $LUCENE_LOGGER.debug "  BEGIN: COMMIT"
        delete_documents # deletes all docuements given @deleted_ids
      
        # are any updated document deleted ?
        deleted_ids = @documents.keys & @deleted_ids
        # delete them those
        deleted_ids.each {|id| @documents.delete(id)}
      
        # update the remaining documents that has not been deleted
        update_documents # update @documents
        
        @documents.clear  # TODO: should we do this in an ensure block ?
        @deleted_ids.clear
        
        # if we are running in a transaction remove this so it will not be commited twice
        Transaction.current.deregister_index(self) if Transaction.running?
        $LUCENE_LOGGER.debug "  END: COMMIT"        
      end
    rescue => ex
      $LUCENE_LOGGER.error(ex)
      #      ex.backtrace.each{|x| $LUCENE_LOGGER.error(x)}
      raise ex
    end


    #
    # Delegetes to the IndexSearcher.find method
    #
    def find(query)
      # new method is a factory method, does not create if it already exists
      searcher = IndexSearcher.new(@path)
      searcher.find(query)
    end
    
    
    def to_s
      "Index [path: '#@path', #{@documents.size} documents]"
    end
    
    #
    # -------------------------------------------------------------------------
    # Private methods
    #
    
    private 

    #
    # There is one lock per index path.
    #
    def lock
      @@locks.synchronize do
        @@locks[@path] ||= Monitor.new
        @@locks[@path]
      end
    end
    
    #
    # Returns true if the index already exists.
    #
    def exist?
      IndexReader.index_exists(@path)
    end

    
    
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
      @key = key.to_s
      @value = value.to_s
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


