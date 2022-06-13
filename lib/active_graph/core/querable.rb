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

          query_run(QueryBuilder.query(*args), options)
        end

        def setup_query!(query, options = {})
          return if options[:skip_instrumentation]
          ActiveSupport::Notifications.instrument('neo4j.core.cypher_query', query: query)
        end

        def query_run(query, options = {})
          setup_query!(query, skip_instrumentation: options[:skip_instrumentation])

          ActiveSupport::Notifications.instrument('neo4j.core.bolt.request') do
            transaction do |tx|
              tx.run(query.cypher, **query.parameters).tap { |result| result.wrap = options[:wrap] != false }
            end
          end
        end
      end
    end
  end
end
