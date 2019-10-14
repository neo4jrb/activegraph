require 'neo4j/core/cypher_session/transactions'

module Neo4j
  module Core
    class CypherSession
      module Transactions
        class Driver < Base
          attr_reader :driver_tx, :driver_session

          def initialize(*args)
            super
            return unless root?
            @driver_session = session.adaptor.driver.session(Neo4j::Driver::AccessMode::WRITE)
            @driver_tx = @driver_session.begin_transaction
          rescue StandardError => e
            clean_transaction_registry
            @driver_tx.close if @driver_tx
            @driver_session.close if @driver_session
            raise e
          end

          def commit
            return unless root?
            begin
              @driver_tx.success
              @driver_tx.close
            ensure
              @driver_session.close
            end
          end

          def delete
            root.driver_tx.failure
            root.driver_tx.close
            root.driver_session.close
          end

          def started?
            true
          end

          def root_tx
            root.driver_tx
          end

          private

          def clean_transaction_registry
            Neo4j::Transaction::TransactionsRegistry.transactions_by_session_id[session.object_id] = []
          end
        end
      end
    end
  end
end
