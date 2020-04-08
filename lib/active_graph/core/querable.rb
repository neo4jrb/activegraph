require 'active_graph/core/instrumentable'
require 'active_graph/transaction'
require 'active_graph/core/query_builder'
require 'active_graph/core/record'

module ActiveGraph
  module Core
    module Querable
      extend ActiveSupport::Concern
      include Instrumentable

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
            transaction do |tx|
              queries.map do |query|
                tx.run(query.cypher, query.parameters).tap { |result| result.wrap = options[:wrap] != false }
              end
            end
          end
        end
      end
    end
  end
end
