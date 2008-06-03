
module Neo4j
  
  
  #
  # Wraps a Neo4j java transaction.
  # There can only be one transaction per thread.
  #
  class Transaction
    attr_reader :neo_transaction
    
    @@counter = 0 # just for debugging purpose, not thread safe ...


    #
    # Runs a block in a Neo4j transaction
    #
    #  Most operations on neo requires an transaction.
    #  include 'neo'
    #
    #  Neo4j::Transaction.run {
    #    node = Neo4j.new
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
    # If a block is not given than the transaction method will return a transaction object.
    #
    #   transaction = Neo4j::Transaction.run
    #
    def self.run
      $NEO_LOGGER.warn{"already start transaction, tried to run start twice"} if Transaction.running?
      raise ArgumentError.new("Expected a block to run in Transaction.run") unless block_given?


      if !Transaction.running? 
        tx = Neo4j::Transaction.new
        tx.start
      else
        tx = Transaction.current
      end
      
      ret = nil
    
      begin  
        ret = yield tx
        tx.success unless tx.failure?
      rescue Exception => e  
        raise e  
      ensure  
        tx.finish  
      end      
      ret
    end  
    
    def initialize
      raise Exception.new("Can't create a new transaction because one is already running (#{Transaction.current})") if Transaction.running?
      @@counter += 1      
      Thread.current[:transaction] = self
      $NEO_LOGGER.debug{"create #{self.to_s}"}
    end
    
    def to_s
      "Transaction: #{@@counter} failure: #{failure?}, running #{Transaction.running?}, thread: #{Thread.current.to_s}"
    end
 
    def self.current
      Thread.current[:transaction]
    end
    
    def self.running?
      self.current != nil && self.current.neo_transaction != nil
    end
    
    def self.failure?
      current.failure?
    end

    def failure?
      @failure == true
    end
    
    #
    # Starts a new transaction
    #
    def start
      @neo_transaction= org.neo4j.api.core.Transaction.begin
      @failure = false      
      
      $NEO_LOGGER.debug{"started #{self.to_s}"}
      self
    end

    
    #
    # Marks this transaction as successful, which means that it will be commited 
    # upon invocation of finish() unless failure()  has or will be invoked before then.
    #
    def success
      raise Exception.new("no transaction started, can't do success on it") unless Transaction.running?
      $NEO_LOGGER.debug{"success #{self.to_s}"}      
      @neo_transaction.success
    end
    
    
    #
    # Commits or marks this transaction for rollback, depending on whether success() or failure() has been previously invoked.
    #
    def finish
      raise Exception.new("no transaction started, can't do success on it") unless Transaction.running?
      @neo_transaction.finish
      @neo_transaction=nil
      Thread.current[:transaction] = nil
      $NEO_LOGGER.debug{"finished #{self.to_s}"}                  
    end

    #
    #  Marks this transaction as failed, which means that it will inexplicably
    #  be rolled back upon invocation of finish().
    #
    def failure
      raise Exception.new("no transaction started, can't do failure on it") unless Transaction.running?
      @neo_transaction.failure
      @failure = true
      $NEO_LOGGER.debug{"failure #{self.to_s}"}                        
    end
    
    
  end
  
    
end
  