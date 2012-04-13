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
        rescue Exception => e
          if Neo4j::Config[:debug_java] && e.respond_to?(:cause)
            puts "Java Exception in a transaction, cause: #{e.cause}"
            e.cause.print_stack_trace
          end
          tx.failure unless tx.nil?
          raise
        end


        def filter(*, &block)
          run &block
        end

        def run
          if running?
            yield self
          else
            begin
              new
              ret = yield self
            rescue
              fail
              raise
            ensure
              finish
            end
            ret
          end
        end

        private
        def new
          Thread.current[:neo4j_transaction] = Neo4j::Transaction.new
        end
      end
    end
  end
end