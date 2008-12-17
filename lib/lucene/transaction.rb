module Lucene
  
  class TransactionAlreadyRunningException < StandardError; end
  class TransactionNotRunningException < StandardError; end
  
  class Transaction
    
    def initialize
      raise TransactionAlreadyRunningException.new if Transaction.running?
      Thread.current[:lucene_transaction] = self
      
      @rollback = false
      @commited = false
      @indexes = {} # key is the path to index, value is the index instance
      $LUCENE_LOGGER.debug{"Created lucene transaction"}
    end

    def to_s
      "Transaction [commited=#@commited, rollback=#@rollback, indexes=#{@indexes.size}, object_id=#{object_id}]"
    end

    
    # Commits all registered Indexes.
    # Stops this transaction (running? will be false)
    #
    def commit
      if !@rollback
        @indexes.each_value do |index| 
          $LUCENE_LOGGER.debug{"BEGIN: Commit index #{index} txt #{to_s}"}        
          index.commit
          $LUCENE_LOGGER.debug{"END: Commited index #{index} txt #{to_s}"}
        end 
      end
      @commited = true
      $LUCENE_LOGGER.error("Index was not removed from commited transaction: #{@indexes.inspect}") if !@indexes.empty? && !@rollback 
      @indexes.clear
      Thread.current[:lucene_transaction] = nil
    end
    
    def failure
      @rollback = true
      $LUCENE_LOGGER.debug{"Rollback Lucene Transaction"}      
    end
    
    def rollback?
      @rollback
    end

    def rollback!
      @rollback = true
    end
    
    #
    # Registers an index to take part of this transaction
    #
    def register_index(key, index)
      @indexes[key] = index
      $LUCENE_LOGGER.debug{"Registered index for #{index}"}
    end

    #
    # Deregister the index so that it will not be part of the transaction
    # any longer.
    #
    def deregister_index(index)
      @indexes.delete index.path
      $LUCENE_LOGGER.debug{"Deregistered index for #{index}"}
    end

    #
    # Deregister all indexes, used for testing purpose.
    #
    def deregister_all_indexes
      @indexes.clear
      $LUCENE_LOGGER.debug{"Deregistered all index, #{@indexes.inspect}"}
    end
    
    
    def index?(path)
      @indexes[path] != nil
    end
    
    def index(path)
      @indexes[path]
    end
    
    #
    # Class methods
    #
    class << self
      def run
        tx = Transaction.new
        begin
          yield tx
        rescue => ex
          tx.failure
          # TODO reuse of error handling and logging
          $LUCENE_LOGGER.error{"Got exception #{ex}"}      
          ex.backtrace.each {|t| $LUCENE_LOGGER.error(t)}
          raise ex
        ensure
          tx.commit unless tx.rollback?
        end
      end

      #
      # Returns the current transaction or nil
      #
      def current
        Thread.current[:lucene_transaction]
      end
      
      
      def running?
        self.current != nil 
      end
    end
  end
  
  
end
