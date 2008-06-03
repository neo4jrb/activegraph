
module Neo4j
  
  #
  # Runs a block in a Neo4j transaction
  #
  #  Most operations on neo requires an transaction.
  #  include 'neo'
  #
  #  Neo4j::transaction {
  #    node = Neo4j.new
  #  }
  #
  # You have also access to transaction object
  #
  #   Neo4j::transaction { |t|
  #     # something failed
  #     t.failure # will cause a rollback
  #   }
  #
  #
  # If a block is not given than the transaction method will return a transaction object.
  #
  #   transaction = Neo4j::transaction
  #   transaction.begin
  # etc ...
  # 
  #
  def transaction     
    return Neo4j::Transaction.new unless block_given?

    tx = Neo4j::Transaction.new
    
    tx.begin
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
  
  module_function :transaction
  
  #
  # Wraps a Neo4j java transaction
  #
  class Transaction
    # holds the wrapped org.neo4j.api.core.Transaction
    attr_accessor :internal

    @@instance = nil
    
    def initialize
      $neo_logger.debug{"create new transaction"}
    end
    
    
    #
    # Get the current transaction
    #
    def self.instance
      @@instance
    end
    
    def failure?
      @failure
    end
    
    #
    # Starts a new transaction
    #
    def begin
        @@instance = self        
        @internal = org.neo4j.api.core.Transaction.begin
        $neo_logger.debug{"begin transaction #{self.to_s}"}
        @failure = false
        self
      end
    
      def to_s
        @internal
      end
      #
      # Marks this transaction as successful, which means that it will be commited 
      # upon invocation of finish() unless failure()  has or will be invoked before then.
      #
      def success
        raise Exception.new("no transaction started, can't do success on it") unless @internal     
        $neo_logger.debug{"success transaction #{self.to_s}"}      
        @internal.success
      end
    
    
      #
      # Commits or marks this transaction for rollback, depending on whether success() or failure() has been previously invoked.
      #
      def finish
        raise Exception.new("no transaction started, can't do success on it") unless @internal     
        $neo_logger.debug{"finish transaction #{self.to_s}"}            
        @internal.finish
        @@instance = nil
      end

      #
      #  Marks this transaction as failed, which means that it will inexplicably
      #  be rolled back upon invocation of finish().
      #
      def failure
        raise Exception.new("no transaction started, can't do failure on it") unless @internal     
        $neo_logger.debug{"failure transaction #{self.to_s}"}                  
        @internal.failure
        @failure = true
      end
    
    
    end
  
    
  end
  
# $neo_logger = Object.new
# def $neo_logger.debug
#   puts yield
# end
#  
# n = Neo4j::Transaction.new
# n.begin
#
