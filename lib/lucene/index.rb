require 'monitor'
require 'lucene/jars'
require 'lucene/transaction'
require 'lucene/index_searcher'
require 'lucene/document'
require 'lucene/field_info'
require 'lucene/field_infos'

#
# A wrapper for the Java lucene search library.
#
module Lucene
  
  class DocumentDeletedException < StandardError; end
  class IdFieldMissingException < StandardError; end
  
  # 
  # Represents a Lucene Index.
  # The index is written/updated only when the commit method is called.
  # This is done since writing to the index file should be done as a batch operation.
  # (Performace will be bad otherwise).
  #  
  class Index
    attr_reader :path, :field_infos, :uncommited
    
     
    # locks per index path, must not write to the same index from 2 threads 
    @@locks = {}    
    @@locks.extend MonitorMixin
    
    def initialize(path, id_field, field_infos=nil)
      # make that another thread finish a commit before creating a new Index belonging
      # to a new transaction/thread
      lock.synchronize do 
        @path = path # where the index is stored on disk
      
        @uncommited = {}  # documents to be commited, a hash of Document
        @deleted_ids = [] # documents to be deleted
      
        if (field_infos.nil?)
          @field_infos = FieldInfos.new(id_field.to_sym)
          # store the id_field, otherwise we can not find it
          @field_infos[id_field] = FieldInfo.new(:store => true)
        else
          # reuse an old field info
          @field_infos = field_infos
        end
      end
    end

    #
    # Tries to reuse an Index instance for the current running transaction.
    # 
    # If a Lucene::Transaction is running it will register this index in that transaction if
    # this has not already been done.
    # When it has been registered in the transaction the transaction will commit the index 
    # when the transaction is commited.
    #
    def self.new(path, id_field = :id)
      # create a new transaction if needed      
      Transaction.new unless Transaction.running?

      # create a new instance only if it does not already exist in the current transaction
      unless Transaction.current.index?(path)
        # TODO We must copy the id_fields or they be lost
        @global_field_infos ||= {}
        instance = super(path, id_field, @global_field_infos[path]) 
        @global_field_infos[path] = instance.field_infos
        Transaction.current.register_index(instance) 
      end

      # return the index for the current transaction
      Transaction.current.index(path)
    end

    #
    # For testing purpose, deletes all field infos that are stored
    #
    def self.delete_field_infos
      @global_field_infos = nil
      Transaction.current.deregister_all_indexes if Transaction.running?
    end
    
    #
    # Delete all uncommited documents. Also deregister this index
    # from the current transaction (if there is one transaction)
    #
    def clear
      lock.synchronize do
        @uncommited.clear
      end
      Transaction.current.deregister_index self if Transaction.running?
    end

    #
    # See instance method Index.clear
    #
    def self.clear(path)
      return unless Transaction.running?
      return unless Transaction.current.index?(path)
      Transaction.current.index(path).clear
    end
    
    #
    # Adds a document to be commited
    #
    def <<(key_values)
      doc = Document.new(@field_infos, key_values)
      lock.synchronize do
        @uncommited[doc.id] = doc
      end
      self
    end
    
    def id_field
      @field_infos.id_field
    end
    
    #
    # Updates the specified document.
    # The index file will not be updated until the transaction commits.
    # The doc is stored in memory till the transaction commits.
    #
    def update(doc)
      lock.synchronize do
        @uncommited[doc.id] = doc
      end
    end
    
    #
    # Delete the specified document.
    # The index file not be updated until the transaction commits.
    # The id of the deleted document is stored in memory till the transaction commits.
    #
    def delete(id)
      lock.synchronize do
        @deleted_ids << id.to_s
      end
    end
    
    
    def deleted?(id)
      @deleted_ids.include?(id.to_s)
    end
    
    def updated?(id)
      @uncommited[id.to_s]
    end
    
    # 
    # 
    # Writes to the index files
    # Open and closes an lucene IndexWriter
    # Close the IndexSearcher so that it will read the updated index next time.
    # This method will automatically be called from a Lucene::Transaction if it was running when the index was created.
    #
    def commit
      # TODO not enough to block threads here, since the @uncommited and @deleted_ids may change
      # Need to synchronize 
      lock.synchronize do
        $LUCENE_LOGGER.debug "  BEGIN: COMMIT"
        delete_documents # deletes all docuements given @deleted_ids
      
        # are any updated document deleted ?
        deleted_ids = @uncommited.keys & @deleted_ids
        # delete them those
        deleted_ids.each {|id| @uncommited.delete(id)}
      
        # update the remaining documents that has not been deleted
        update_documents # update @documents
        
        @uncommited.clear  # TODO: should we do this in an ensure block ?
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
    def find(query=nil, &block)
      # new method is a factory method, does not create if it already exists
      searcher = IndexSearcher.new(@path)
      
      if block.nil?
        return searcher.find(@field_infos, query) 
      else
        return searcher.find_dsl(@field_infos, &block) 
      end
    end
    
    
    def to_s
      "Index [path: '#@path', #{@uncommited.size} documents]"
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

    #
    # --------------------------------------------------------------------------
    # 
    private
    
    def update_documents
      index_writer = IndexWriter.new(@path, StandardAnalyzer.new, ! exist?)
      @uncommited.each_value do |doc|
        # removes the document and adds it
        doc.update(index_writer)
      end
    ensure
      # TODO exception handling, what if ...
      index_writer.close
    end


    def delete_documents
      return unless exist? # if no index exists then there is nothing to do
      
      writer = IndexWriter.new(@path, StandardAnalyzer.new, false)
      id_field = @field_infos[@field_infos.id_field]
      
      @deleted_ids.each do |id|
        converted_value = id_field.convert_to_lucene(id)        
        writer.deleteDocuments(Term.new(@field_infos.id_field.to_s, converted_value))
      end
    ensure
      # TODO exception handling, what if ...
      writer.close unless writer.nil?
    end
    

  end
end


