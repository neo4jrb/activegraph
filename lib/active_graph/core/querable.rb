require 'active_graph/core/instrumentable'
require 'active_graph/transaction'
require 'active_graph/core/query_builder'
require 'active_graph/core/responses'

module ActiveGraph
  module Core
    module Querable
      extend ActiveSupport::Concern
      include Instrumentable
      include Responses

      class_methods do
        def query(*args)
          options = case args.size
                    when 3
                      args.pop
                    when 2
                      args.pop if args[0].is_a?(::ActiveGraph::Core::Query)
                    end || {}

          queries(options) { append(*args) }[0]
        end

        def queries(options = {}, &block)
          query_builder = QueryBuilder.new

          query_builder.instance_eval(&block)

          transaction do
            query_set(query_builder.queries, options)
          end
        end

        def setup_queries!(queries, options = {})
          return if options[:skip_instrumentation]
          queries.each do |query|
            ActiveSupport::Notifications.instrument('neo4j.core.cypher_query', query: query)
          end
        end

        def query_set(queries, options = {})
          setup_queries!(queries, skip_instrumentation: options[:skip_instrumentation])

          ActiveSupport::Notifications.instrument('neo4j.core.bolt.request') do
            self.wrap_level = options[:wrap_level]
            transaction do |tx|
              queries.map do |query|
                result_from_data(tx.run(query.cypher, query.parameters))
              end
            end
          rescue Neo4j::Driver::Exceptions::Neo4jException => e
            raise ActiveGraph::Core::CypherError.new_from(e.code, e.message) # , e.stack_track.to_a
          end
        end
      end
    end
  end
end
