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
      class << self
        def new
          finish if Thread.current[:neo4j_transaction]
          Thread.current[:neo4j_transaction] = Neo4j::Transaction.new
        end

        def current
          Thread.current[:neo4j_transaction]
        end

        def running?
          Thread.current[:neo4j_transaction] != nil
        end

        def fail?
          Thread.current[:neo4j_transaction_fail] != nil
        end

        def fail
          Thread.current[:neo4j_transaction_fail] = true
        end

        def success
          Thread.current[:neo4j_transaction_fail] = nil
        end

        def finish
          tx = Thread.current[:neo4j_transaction]
          tx.success unless fail?
          tx.finish
          Thread.current[:neo4j_transaction] = nil
          Thread.current[:neo4j_transaction_fail] = nil
        end

        def filter(*, &block)
          run &block
        end

        def run
          begin
            new
            yield
          rescue
            fail
            raise
          ensure
            finish
          end
        end
      end
    end
  end
end