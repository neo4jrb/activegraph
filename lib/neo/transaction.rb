
module Neo
  
  
  #
  # Wraps a Neo java transaction
  #
  class Transaction
    # holds the wrapped org.neo4j.api.core.Transaction
    attr_accessor :internal

    def initialize
      $neo_logger.debug{"create new transaction"}
      
    end
    
    def failure?
      @failure
    end
    
    #
    # Starts a new transaction
    #
    def begin
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
# n = Neo::Transaction.new
# n.begin
#
