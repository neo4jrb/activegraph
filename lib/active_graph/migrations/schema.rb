module ActiveGraph
  module Migrations
    module Schema
      class << self
        def fetch_schema_data
          %i[constraints indexes].to_h { |schema_elem| [schema_elem, send("fetch_#{schema_elem}_descriptions").keys] }
        end

        def synchronize_schema_data(schema_data, remove_missing)
          queries =
            ActiveGraph::Base.read_transaction do
              drop_and_create_queries(fetch_constraints_descriptions, schema_data[:constraints], 'CONSTRAINT', remove_missing) +
                drop_and_create_queries(fetch_indexes_descriptions, schema_data[:indexes], 'INDEX', remove_missing)
            end
          ActiveGraph::Base.write_transaction do
            queries.each(&ActiveGraph::Base.method(:query))
          end
        end

        private

        def fetch_indexes_descriptions
            ActiveGraph::Base.raw_indexes.reject(&ActiveGraph::Base.method(:constraint_owned?))
                             .then(&ActiveGraph::Base.method(:normalize)).then(&method(:fetch_descriptions))
        end

        def fetch_constraints_descriptions
          fetch_descriptions(ActiveGraph::Base.constraints)
        end

        def fetch_descriptions(results)
          results.map { |definition| definition.values_at(:create_statement, :name) }.sort.to_h
        end

        def drop_and_create_queries(existing, specified, schema_elem, remove_missing)
          (remove_missing ? existing.except(*specified).map { |stmt, name| drop_statement(schema_elem, stmt, name) } : []) +
            (specified - existing.keys).map(&method(:create_statement))
        end

        def drop_statement(schema_elem, create_statement, name)
          "DROP #{name&.then { |name| "#{schema_elem} #{name}" } || create_statement}"
        end

        def create_statement(stmt)
          stmt.start_with?('CREATE ') ? stmt : "CREATE #{stmt}"
        end
      end
    end
  end
end
