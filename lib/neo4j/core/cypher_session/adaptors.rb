require 'neo4j/core/cypher_session'
require 'neo4j/core/instrumentable'
require 'neo4j/core/label'
require 'neo4j/core/logging'
require 'neo4j/ansi'

module Neo4j
  module Core
    class CypherSession
      class CypherError < StandardError
        attr_reader :code, :original_message, :stack_trace

        def initialize(code = nil, original_message = nil, stack_trace = nil)
          @code = code
          @original_message = original_message
          @stack_trace = stack_trace

          msg = <<-ERROR
  Cypher error:
  #{ANSI::CYAN}#{code}#{ANSI::CLEAR}: #{original_message}
  #{stack_trace}
ERROR
          super(msg)
        end

        def self.new_from(code, message, stack_trace = nil)
          error_class_from(code).new(code, message, stack_trace)
        end

        def self.error_class_from(code)
          case code
          when /(ConstraintValidationFailed|ConstraintViolation)/
            SchemaErrors::ConstraintValidationFailedError
          when /IndexAlreadyExists/
            SchemaErrors::IndexAlreadyExistsError
          when /ConstraintAlreadyExists/ # ?????
            SchemaErrors::ConstraintAlreadyExistsError
          else
            CypherError
          end
        end
      end
      module SchemaErrors
        class ConstraintValidationFailedError < CypherError; end
        class ConstraintAlreadyExistsError < CypherError; end
        class IndexAlreadyExistsError < CypherError; end
      end
      class ConnectionFailedError < StandardError; end

      module Adaptors
        MAP = {}

        class Base
          include Neo4j::Core::Instrumentable

          gem_name, version = ['neo4j', ::Neo4j::VERSION]

          USER_AGENT_STRING = "#{gem_name}-gem/#{version} (https://github.com/neo4jrb/#{gem_name})"

          def connect(*_args)
            fail '#connect not implemented!'
          end

          attr_accessor :wrap_level
          attr_reader :options

          Query = Struct.new(:cypher, :parameters, :pretty_cypher, :context)

          class QueryBuilder
            attr_reader :queries

            def initialize
              @queries = []
            end

            def append(*args)
              query = case args.map(&:class)
                      when [String], [String, Hash]
                        Query.new(args[0], args[1] || {})
                      when [::Neo4j::Core::Query]
                        args[0]
                      else
                        fail ArgumentError, "Could not determine query from arguments: #{args.inspect}"
                      end

              @queries << query
            end

            def query
              # `nil` sessions are just a workaround until
              # we phase out `Query` objects containing sessions
              Neo4j::Core::Query.new(session: nil)
            end
          end

          def query(session, *args)
            options = case args.size
                      when 3
                        args.pop
                      when 2
                        args.pop if args[0].is_a?(::Neo4j::Core::Query)
                      end || {}

            queries(session, options) { append(*args) }[0]
          end

          def queries(session, options = {}, &block)
            query_builder = QueryBuilder.new

            query_builder.instance_eval(&block)

            new_or_current_transaction(session, options[:transaction]) do |tx|
              query_set(tx, query_builder.queries, {commit: !options[:transaction]}.merge(options))
            end
          end

          %i[query_set
             version
             indexes
             constraints
             connected?].each do |method|
            define_method(method) do |*_args|
              fail "##{method} method not implemented on adaptor!"
            end
          end

          # If called without a block, returns a Transaction object
          # which can be used to call query/queries/mark_failed/commit
          # If called with a block, the Transaction object is yielded
          # to the block and `commit` is ensured.  Any uncaught exceptions
          # will mark the transaction as failed first
          def transaction(session)
            return self.class.transaction_class.new(session) if !block_given?

            begin
              tx = transaction(session)

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
            validate_connection!(transaction)

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

          def close; end

          def supports_metadata?
            true
          end

          class << self
            def transaction_class
              fail '.transaction_class method not implemented on adaptor!'
            end
          end

          private

          def new_or_current_transaction(session, tx, &block)
            if tx
              yield(tx)
            else
              transaction(session, &block)
            end
          end

          def validate_connection!(transaction)
            fail 'Query attempted without a connection' if !connected?
            fail "Invalid transaction object: #{transaction}" if !transaction.is_a?(self.class.transaction_class)
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
end
