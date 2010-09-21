module Neo4j
  module Rails

    # This method is typically used in an Rails ActionController as a filter method.
    # It will guarantee that an transaction is create before your action is called,
    # and that the transaction is finished after your action is called.
    #
    # Example:
    #  class MyController < ActionController::Base
    #      around_filter Neo4j::Rails::Transaction, :only => [:edit, :delete]
    #      ...
    #  end
    class Transaction
      def self.filter(*)
        begin
          tx = Neo4j::Transaction.new
          yield
          tx.success
        rescue Exception
          tx.failure unless tx.nil?
          raise
        ensure
          tx.finish unless tx.nil?
        end
      end
    end
  end

end