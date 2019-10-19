require 'neo4j/transaction'

module Neo4j
  module Core
    module CypherSession
      class Transaction < Neo4j::Transaction::Base
        attr_reader :driver_tx, :driver_session

        def initialize(*args)
          super
          return unless root?
          @driver_session = driver.driver.session(Neo4j::Driver::AccessMode::WRITE)
          @driver_tx = @driver_session.begin_transaction
        rescue StandardError => e
          clean_transaction_registry
          @driver_tx.close if @driver_tx
          @driver_session.close if @driver_session
          raise e
        end

        def query(*args)
          options = if args[0].is_a?(::Neo4j::Core::Query)
                      args[1] ||= {}
                    else
                      args[1] ||= {}
                      args[2] ||= {}
                    end
          options[:transaction] ||= self

          driver.query(*args)
        end

        def queries(options = {}, &block)
          driver.queries({ transaction: self }.merge(options), &block)
        end

        def after_commit_registry
          @after_commit_registry ||= []
        end

        def after_commit(&block)
          after_commit_registry << block
        end

        def post_close!
          super
          after_commit_registry.each(&:call) unless failed?
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
          Neo4j::Transaction::TransactionsRegistry.transactions_by_session_id = []
        end
      end
    end
  end
end
