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

      # Acquires a write lock for entity for this transaction. The lock (returned from this method) can be released manually, but if not it's released automatically when the transaction finishes.
      # There is no implementation for this here because it's an java method
      #
      # @param [Neo4j::Relationship, Neo4j::Node] java_entity the entity to acquire a lock for. If another transaction currently holds a write lock to that entity this call will wait until it's released.
      # @return [Java::OrgNeo4jGraphdb::Lock] a Lock which optionally can be used to release this lock earlier than when the transaction finishes. If not released (with Lock.release() it's going to be released with the transaction finishes.
      # @see http://api.neo4j.org/current/org/neo4j/graphdb/Transaction.html#acquireWriteLock(Java::OrgNeo4jGraphdb::PropertyContainer)
      # @see http://api.neo4j.org/current/org/neo4j/graphdb/Lock.html
      def acquire_write_lock(java_entity)
      end

      # Acquires a read lock for entity for this transaction. The lock (returned from this method) can be released manually, but if not it's released automatically when the transaction finishes.
      # There is no implementation for this here because it's an java method
      # @param [Neo4j::Relationship, Neo4j::Node] java_entity the entity to acquire a lock for. If another transaction currently hold a write lock to that entity this call will wait until it's released.
      # @return [Java::OrgNeo4jGraphdb::Lock]  a Lock which optionally can be used to release this lock earlier than when the transaction finishes. If not released (with Lock.release() it's going to be released with the transaction finishes.
      # @see http://api.neo4j.org/current/org/neo4j/graphdb/Transaction.html#acquireReadLock(Java::OrgNeo4jGraphdb::PropertyContainer)
      # @see http://api.neo4j.org/current/org/neo4j/graphdb/Lock.html
      def acquire_read_lock(java_entity)
      end

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