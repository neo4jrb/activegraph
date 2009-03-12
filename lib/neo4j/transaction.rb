module Neo4j
  
  #
  # Raised when an operation was called without a running transaction.
  #
  class NotInTransactionError < StandardError; end
  
  
  #
  # Raised when an operation was called when an transaction was already running.
  #
  class AlreadyInTransactionError < StandardError; end
  
  
  #
  # Wraps a Neo4j java transaction and lucene transactions.
  # There can only be one transaction per thread.
  #
  class Transaction
    attr_reader :neo_tx
    
    @@counter = 0 # just for debugging purpose

    

    # --------------------------------------------------------------------------
    #
    # Class methods
    #
    class << self 
      

      #
      # debugging method
      #
      def called
        res = ""
        for i in 2..7 do
          res << /\`([^\']+)\'/.match(caller(i).first)[1]
          res << ', ' unless i == 4
        end
        res
      end 

      def placebo?(tx)
        Neo4j.instance.placebo_tx == tx
      end

      # Creates a transaction. If one is already running then a 'placebo' transaction will be created instead.
      # A placebo transactions wraps the real transaction by not allowing the finish method to finish the
      # real transaction.
      #
      def new
        neo_tx= Neo4j.instance.begin_transaction
        if placebo?(neo_tx)
          raise StandardError.new("Neo4j created a placebo transaction but an real transaction did not exist yet") if !Transaction.running?
          Transaction.current.placebo
        else
          super(neo_tx)
        end
      end
      
      # Runs a block in a Neo4j transaction
      #
      # Most operations on neo requires an transaction. In Neo4j all read and write operations are
      # wrapped automatically in an transaction. You will get much better performance if
      # one transaction is wrapped around several neo operation instead of running one transaction per
      # neo operation.
      # If one transaction is already running then a 'placebo' transaction will be created.
      # Performing a finish on a placebo transaction will not finish the 'real' transaction.
      #  
      # ==== Params
      # @yield the block to be performed in one transaction
      # @yieldparam [Neo4j::Transaction] The transaction
      #
      # ==== Examples
      #  include 'neo4j'
      #
      #  Neo4j::Transaction.run {
      #    node = PersonNode.new
      #  }
      #
      # You have also access to transaction object
      #
      #   Neo4j::Transaction.run { |t|
      #     # something failed
      #     t.failure # will cause a rollback
      #   }
      #
      #
      # ==== Returns
      # The value of the evaluated provided block
      #
      # :api: public
      #
      def run
        $NEO_LOGGER.info{"new transaction " + called}
        raise ArgumentError.new("Expected a block to run in Transaction.run") unless block_given?

        ret = nil
    
        begin
          tx = Neo4j::Transaction.new
          ret = yield tx
          tx.success unless tx.failure?
        rescue Exception => e  
          $NEO_LOGGER.warn{"Neo transaction rolled back because of an exception, #{e}"}
          $NEO_LOGGER.warn{e.backtrace.join("\n")}
          tx.failure
          raise e  
        ensure  
          tx.finish  
        end      
        ret
      end  

      def current
        Thread.current[:transaction]
      end
    
      def running?
        self.current != nil && self.current.neo_tx != nil
      end
    
      def failure?
        current.failure?
      end
    end

  
    #
    # --------------------------------------------------------------------------
    # Instance methods
    #
    
    
    def initialize(neo_tx)
      raise AlreadyInTransactionError.new if Transaction.running?
      @neo_tx = neo_tx
      @@counter += 1
      @id = @@counter
      @failure = false      
      Thread.current[:transaction] = self
      $NEO_LOGGER.debug{"create #{self.to_s}"}
    end
    
    def to_s
      "Transaction: placebo: #{placebo?}, #{@id} failure: #{failure?}, running #{Transaction.running?}, thread: #{Thread.current.to_s} #{@neo_tx}"
    end
 

    def failure?
      @failure == true
    end

    def placebo?
      @neo_tx == Neo4j.instance.placebo_tx
    end

    def placebo
      @placebo ||= PlaceboTransaction.new(self)
    end
    
    
    # Marks this transaction as successful, which means that it will be commited 
    # upon invocation of finish() unless failure()  has or will be invoked before then.
    # 
    # :api: public
    def success
      raise NotInTransactionError.new unless Transaction.running?
      $NEO_LOGGER.info{"success #{self.to_s}"}      
      @neo_tx.success
    end
    
    
    # Commits or marks this transaction for rollback, depending on whether
    # success() or failure() has been previously invoked.
    #
    # :api: public
    def finish
      raise NotInTransactionError.new unless Transaction.running?
      @neo_tx.finish
      @neo_tx=nil
      Thread.current[:transaction] = nil
      
      if Lucene::Transaction.running?
        $NEO_LOGGER.debug{"LUCENE TX running failure: #{failure?}"}
        
        # mark lucene transaction for failure if the neo transaction fails
        Lucene::Transaction.current.failure if failure?
        Lucene::Transaction.current.commit 
      else
        $NEO_LOGGER.debug{"NO LUCENE TX running"}
      end
          
      
      $NEO_LOGGER.info{"finished #{self.to_s}"}                  
    end

    # Marks this transaction as failed, which means that it will inexplicably
    # be rolled back upon invocation of finish().
    #
    # :api: public
    def failure
      raise NotInTransactionError.new unless Transaction.running?
      @neo_tx.failure
      @failure = true
      $NEO_LOGGER.info{"failure #{self.to_s}"}                        
    end
    
  end
  
  #
  # This is returned when trying to create a new transaction while a transaction is already running.
  # This class will do nothing when the finish method is called.
  # Finish will only be called when the 'real' transaction does it.
  #
  class PlaceboTransaction < DelegateClass(Transaction)
    
    def initialize(tx)
      super(tx)
      @tx = tx # store it only for logging purpose
    end
    
    #
    # Do nothing since Neo4j does not support chained transactions.
    # 
    def finish
      $NEO_LOGGER.info{"tried to finish chained transaction #{@tx}"}
    end
  end
  
end
