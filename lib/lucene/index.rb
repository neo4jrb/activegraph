require 'monitor'
require 'lucene/jars'
require 'lucene/transaction'
require 'lucene/index_searcher'
require 'lucene/document'
require 'lucene/field_info'
require 'lucene/index_info'

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
    attr_reader :path, :uncommited
    
     
    # locks per index path, must not write to the same index from 2 threads 
    @@locks = {}    
    @@locks.extend MonitorMixin
    
    def initialize(path, index_info)
      @path = path # a key (i.e. filepath) where the index is stored on disk/or RAM              
      @index_info = index_info # the actual storage of the index
      @uncommited = {}  # documents to be commited, a hash of Document
      @deleted_ids = [] # documents to be deleted
    end

    def field_infos
      IndexInfo.instance(@path)
    end


    # Returns an Index instance for the current running transaction.
    #
    # Tries to reuse an Index instance for the current running transaction.
    # If a Lucene::Transaction is running it will register this index in that transaction if
    # this has not already been done.
    # When it has been registered in the transaction the transaction will commit the index
    # when the transaction is finished.
    # The configuration (kept in the #field_infos) for this index will be the same for all indexes with the same path/key.
    #
    # ==== Parameters
    # path<String>:: The key or location where the index should be stored (relative Lucene::Config[:storage_path]
    #
    # ==== Examples
    # Index.new 'foo/lucene-db'
    #
    # ==== Returns
    # Returns a new or an already existing Index
    #
    # :api: public
    def self.new(path)
      # make sure no one modifies the index specified at given path
      lock(path).synchronize do
        # create a new transaction if needed      
        Transaction.new unless Transaction.running?

        # create a new instance only if it does not already exist in the current transaction
        unless Transaction.current.index?(path)
          $LUCENE_LOGGER.debug{"Index#new #{path} not in current transaction => new index"}
          info = IndexInfo.instance(path)
          index = super(path, info)
          Transaction.current.register_index(path, index) 
        end

        $LUCENE_LOGGER.debug{"Index#new '#{path}' #{Transaction.current.index(path)}"}
        # return the index for the current transaction
        Transaction.current.index(path)
      end
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
    
    # Creates a new document from the given hash of values.
    # This document will be stored in this instance till it is commited.
    #
    # ==== Parameters
    # path<String>:: The key or location where the index should be stored (relative Lucene::Config[:storage_path]
    #
    # ==== Examples
    # index = Index.new('name_or_path_to_index')
    # index << {:id=>'1', :name=>'foo'} 
    #
    # ==== Returns
    # Returns the index instance so that this method can be chained
    #
    # :api: public
    def <<(key_values)
      doc = Document.new(field_infos, key_values)
      lock.synchronize do
        @uncommited[doc.id] = doc
      end
      self
    end
    
    def id_field
      @index_info.id_field
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
    def find(*query, &block)
      # new method is a factory method, does not create if it already exists
      searcher = IndexSearcher.new(@index_info.storage)
			
      # check sorting parameters
      query.last == :sort_by
      query.find{|x| x == :sort_by}
			
      if block.nil?
        case query.first
        when String
          return searcher.find(@index_info, query)           
        when Hash, Array
          return searcher.find(@index_info, query.first) 
        end
      else
        return searcher.find_dsl(@index_info, &block) 
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

    def self.lock(path)
      @@locks.synchronize do
        @@locks[path] ||= Monitor.new
        @@locks[path]
      end
    end
    
    #
    # Returns true if the index already exists.
    #
    def exist?
      @index_info.index_exists?
    end

    #
    # --------------------------------------------------------------------------
    # 
    private
    
    def update_documents
      index_writer = org.apache.lucene.index.IndexWriter.new(@index_info.storage, org.apache.lucene.analysis.standard.StandardAnalyzer.new, ! exist?)
      @uncommited.each_value do |doc|
        # removes the document and adds it again
        doc.update(index_writer)
      end
    ensure
      # TODO exception handling, what if ...
      index_writer.close
    end


    def delete_documents
      return unless exist? # if no index exists then there is nothing to do
      
      writer = org.apache.lucene.index.IndexWriter.new(@index_info.storage, org.apache.lucene.analysis.standard.StandardAnalyzer.new, false)
      id_field = @index_info.infos[@index_info.id_field]
      
      @deleted_ids.each do |id|
        converted_value = id_field.convert_to_lucene(id)
        writer.deleteDocuments(org.apache.lucene.index.Term.new(@index_info.id_field.to_s, converted_value))
      end
    ensure
      # TODO exception handling, what if ...
      writer.close unless writer.nil?
    end
    

  end
end


