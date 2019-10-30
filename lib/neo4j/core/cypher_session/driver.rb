require 'active_support/core_ext/module/attribute_accessors'
require 'neo4j/core/instrumentable'
require 'neo4j/core/label'
require 'neo4j/core/logging'
require 'neo4j/ansi'
require 'neo4j/transaction'
require 'neo4j/core/cypher_session/connection_failed_error'
require 'neo4j/core/cypher_session/cypher_error'
require 'neo4j/core/cypher_session/schema_errors'
require 'neo4j/core/cypher_session/query_builder'
require 'neo4j/core/cypher_session/has_uri'
require 'neo4j/core/cypher_session/schema'
require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    module CypherSession
      class Driver
        include Neo4j::Core::Instrumentable
        include HasUri
        include Schema
        include Responses

        USER_AGENT_STRING = "neo4j-gem/#{::Neo4j::VERSION} (https://github.com/neo4jrb/neo4j)"

        cattr_reader :singleton
        attr_accessor :wrap_level
        attr_reader :options, :driver
        delegate :close, to: :driver

        @@mutex = Mutex.new
        at_exit do
          close
        end

        default_url('bolt://neo4:neo4j@localhost:7687')

        validate_uri do |uri|
          uri.scheme == 'bolt'
        end

        class << self
          def singleton=(driver)
            @@mutex.synchronize do
              singleton&.close
              class_variable_set(:@@singleton, driver)
            end
          end

          def new_instance(url)
            uri = URI(url)
            user = uri.user
            password = uri.password
            auth_token = if user
                           Neo4j::Driver::AuthTokens.basic(user, password)
                         else
                           Neo4j::Driver::AuthTokens.none
                         end
            Neo4j::Driver::GraphDatabase.driver(url, auth_token)
          end

          def close
            singleton&.close
          end
        end

        def initialize(url, options = {})
          self.url = url
          @driver = self.class.new_instance(url)
          self.class.singleton = self
          @options = options
        end

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

        def logger
          return @logger if @logger

          @logger = if @options[:logger]
                      @options[:logger]
                    else
                      Logger.new(logger_location).tap do |logger|
                        logger.level = logger_level
                      end
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
            raise Neo4j::Core::CypherSession::CypherError.new_from(e.code, e.message) # , e.stack_track.to_a
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

        def logger_location
          @options[:logger_location] || STDOUT
        end

        def logger_level
          @options[:logger_level] || Logger::WARN
        end
      end
    end
  end
end
