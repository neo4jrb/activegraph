require 'neo4j/core/instrumentable'
require 'neo4j/core/label'
require 'neo4j/core/logging'
require 'neo4j/ansi'
require 'neo4j/core/cypher_session/driver_registry'
require 'neo4j/transaction'
require 'neo4j/core/cypher_session/connection_failed_error'
require 'neo4j/core/cypher_session/cypher_error'
require 'neo4j/core/cypher_session/schema_errors'
require 'neo4j/core/cypher_session/query_builder'
require 'neo4j/core/cypher_session/has_uri'
require 'neo4j/core/cypher_session/schema'

module Neo4j
  module Core
    module CypherSession
      class Driver
        include Neo4j::Core::Instrumentable
        include HasUri
        include Schema

        USER_AGENT_STRING = "neo4j-gem/#{::Neo4j::VERSION} (https://github.com/neo4jrb/neo4j)"

        attr_accessor :wrap_level
        attr_reader :options, :driver

        default_url('bolt://neo4:neo4j@localhost:7687')

        validate_uri do |uri|
          uri.scheme == 'bolt'
        end

        def initialize(url, options = {})
          self.url = url
          @driver = DriverRegistry.instance.driver_for(url)
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

        def setup_queries!(queries, transaction, options = {})
          return if options[:skip_instrumentation]
          queries.each do |query|
            self.class.instrument_query(query, self) {}
          end
        end

        EMPTY = ''
        NEWLINE_W_SPACES = "\n  "

        instrument(:query, 'neo4j.core.cypher_query', %w[query adaptor]) do |_, _start, _finish, _id, payload|
          query = payload[:query]
          params_string = (query.parameters && !query.parameters.empty? ? "| #{query.parameters.inspect}" : EMPTY)
          cypher = query.pretty_cypher ? (NEWLINE_W_SPACES if query.pretty_cypher.include?("\n")).to_s + query.pretty_cypher.gsub(/\n/, NEWLINE_W_SPACES) : query.cypher

          source_line, line_number = Logging.first_external_path_and_line(caller_locations)

          " #{ANSI::CYAN}#{query.context || 'CYPHER'}#{ANSI::CLEAR} #{cypher} #{params_string}" +
            ("\n   ↳ #{source_line}:#{line_number}" if payload[:adaptor].options[:verbose_query_logs] && source_line).to_s
        end

        def default_subscribe
          subscribe_to_request
        end

        def supports_metadata?
          true
        end

        def close
          DriverRegistry.instance.close(driver)
        end

        def query_set(transaction, queries, options = {})
          setup_queries!(queries, transaction, skip_instrumentation: options[:skip_instrumentation])

          responses = queries.map do |query|
            transaction.root_tx.run(query.cypher, query.parameters)
          end
          wrap_level = options[:wrap_level] || @options[:wrap_level]
          Responses.new(responses, wrap_level: wrap_level).to_a
        rescue Neo4j::Driver::Exceptions::Neo4jException => e
          raise Neo4j::Core::CypherSession::CypherError.new_from(e.code, e.message) # , e.stack_track.to_a
        end

        instrument(:request, 'neo4j.core.bolt.request', %w[adaptor body]) do |_, start, finish, _id, payload|
          ms = (finish - start) * 1000
          adaptor = payload[:adaptor]

          type = nil # adaptor.ssl? ? '+TLS' : ' UNSECURE'
          " #{ANSI::BLUE}BOLT#{type}:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{adaptor.url_without_password}"
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
