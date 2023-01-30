module ActiveGraph
  module Migrations
    module Schema
      class << self
        def fetch_schema_data
          %i[constraints indexes].to_h { |schema_elem| [schema_elem, fetch_descriptions(schema_elem).keys] }
        end

        def synchronize_schema_data(schema_data, remove_missing)
          queries =
            ActiveGraph::Base.read_transaction do
              drop_and_create_queries(fetch_descriptions(:constraints), schema_data[:constraints], 'CONSTRAINT', remove_missing) +
                drop_and_create_queries(fetch_descriptions(:indexes), schema_data[:indexes], 'INDEX', remove_missing)
            end
          ActiveGraph::Base.write_transaction do
            queries.each(&ActiveGraph::Base.method(:query))
          end
        end

        private

        def fetch_descriptions(schema_elem)
          ActiveGraph::Base.send(schema_elem).map { |definition| definition.values_at(:create_statement, :name) }.sort
                           .to_h
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
