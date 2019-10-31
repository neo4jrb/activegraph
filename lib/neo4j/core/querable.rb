require 'neo4j/core/instrumentable'
require 'neo4j/transaction'
require 'neo4j/core/query_builder'
require 'neo4j/core/responses'

module Neo4j
  module Core
    module Querable
      extend ActiveSupport::Concern
      include Instrumentable
      include Responses

      def query(*args)
        options = case args.size
                  when 3
                    args.pop
                  when 2
                    args.pop if args[0].is_a?(::Neo4j::Core::Query)
                  end || {}

        queries(options) { append(*args) }[0]
      end

      def queries(options = {}, &block)
        query_builder = QueryBuilder.new

        query_builder.instance_eval(&block)

        new_or_current_transaction(options[:transaction]) do |tx|
          query_set(tx, query_builder.queries, { commit: !options[:transaction] }.merge(options))
        end
      end

# If called without a block, returns a Transaction object
# which can be used to call query/queries/mark_failed/commit
# If called with a block, the Transaction object is yielded
# to the block and `commit` is ensured.  Any uncaught exceptions
# will mark the transaction as failed first
      def transaction
        return Transaction.new(self) if !block_given?

        begin
          tx = transaction

          yield tx
        rescue => e
          tx.mark_failed if tx

          raise e
        ensure
          tx.close if tx
        end
      end

      def setup_queries!(queries, options = {})
        return if options[:skip_instrumentation]
        queries.each do |query|
          ActiveSupport::Notifications.instrument('neo4j.core.cypher_query', query: query)
        end
      end

      def query_set(transaction, queries, options = {})
        setup_queries!(queries, skip_instrumentation: options[:skip_instrumentation])

        ActiveSupport::Notifications.instrument('neo4j.core.bolt.request') do
          self.wrap_level = options[:wrap_level]
          queries.map do |query|
            result_from_data(transaction.root_tx.run(query.cypher, query.parameters))
          end
        rescue Neo4j::Driver::Exceptions::Neo4jException => e
          raise Neo4j::Core::CypherError.new_from(e.code, e.message) # , e.stack_track.to_a
        end
      end

      private

      def new_or_current_transaction(tx, &block)
        if tx
          yield(tx)
        else
          transaction(&block)
        end
      end
    end
  end
end
