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

  class DocumentDeletedException < StandardError;
  end
  class IdFieldMissingException < StandardError;
  end

  # 
  # Represents a Lucene Index.
  # The index is written/updated only when the commit method is called.
  # This is done since writing to the index file should be done as a batch operation.
  # (Performance will be bad otherwise).
  #
  # For each Thread there is zero or one Index instance. There are at most one Index instance per thread
  # so there is no need for this class to use synchronization for Thread safety.
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
    def self.new(path)
      # make sure no one modifies the index specified at given path
      lock(path).synchronize do
        # create a new transaction if needed
        Transaction.new unless Transaction.running?

        # create a new instance only if it does not already exist in the current transaction
        unless Transaction.current.index?(path)
          info = IndexInfo.instance(path)
          index = super(path, info)
          Transaction.current.register_index(path, index)
        end
      end
      # return the index for the current transaction
      Transaction.current.index(path)
    end


    #
    # Delete all uncommited documents. Also deregister this index
    # from the current transaction (if there is one transaction)
    #
    def clear
      @uncommited.clear
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
    def <<(key_values)
      doc = Document.new(field_infos, key_values)
      @uncommited[doc.id] = doc
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
      @uncommited[doc.id] = doc
    end

    #
    # Delete the specified document.
    # The index file not be updated until the transaction commits.
    # The id of the deleted document is stored in memory till the transaction commits.
    #
    def delete(id)
      @deleted_ids << id.to_s
    end


    def deleted?(id)
      @deleted_ids.include?(id.to_s)
    end

    def updated?(id)
      @uncommited[id.to_s]
    end

    # Writes to the index files.
    # Open and closes an lucene IndexWriter
    # Close the IndexSearcher so that it will read the updated index next time.
    # This method will automatically be called from a Lucene::Transaction if it was running when the index was created.
    #
    # This method is synchronized since it is not allowed to update a lucene index from several threads at the same time.
    #
    def commit
      lock.synchronize do
        delete_documents # deletes all documents given @deleted_ids

        # are any updated document deleted ?
        deleted_ids = @uncommited.keys & @deleted_ids
        # make sure we don't index deleted document
        deleted_ids.each {|id| @uncommited.delete(id)}

        # update the remaining documents that has not been deleted

        begin
          index_writer = org.apache.lucene.index.IndexWriter.new(@index_info.storage, @index_info.analyzer, ! exist?)
          # removes the document and adds it again
          @uncommited.each_value { |doc| doc.update(index_writer) }
        ensure
          # TODO exception handling, what if ...
          index_writer.close

          @uncommited.clear
          @deleted_ids.clear

          # if we are running in a transaction remove this so it will not be committed twice
          Transaction.current.deregister_index(self) if Transaction.running?
        end
      end
    end


    #
    # Delegates to the IndexSearcher.find method
    #
    def find(*query, &block)
      # new method is a factory method, does not create if it already exists
      searcher = IndexSearcher.new(@index_info.storage)

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

    def delete_documents # :nodoc:
      return unless exist? # if no index exists then there is nothing to do

      writer = org.apache.lucene.index.IndexWriter.new(@index_info.storage, @index_info.analyzer, false)
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


