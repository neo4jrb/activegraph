module Neo4j
  module Migrations
    module Schema
      class << self
        def fetch_schema_data(session)
          {constraints: fetch_constraint_descriptions(session).sort,
           indexes: fetch_index_descriptions(session).sort}
        end

        def synchronize_schema_data(session, schema_data, remove_missing)
          queries = []
          queries += drop_and_create_queries(fetch_constraint_descriptions(session), schema_data[:constraints], remove_missing)
          queries += drop_and_create_queries(fetch_index_descriptions(session), schema_data[:indexes], remove_missing)
          session.queries do
            queries.each { |query| append query }
          end
        end

        private

        def fetch_constraint_descriptions(session)
          session.query('CALL db.constraints()').map(&:description)
        end

        def fetch_index_descriptions(session)
          result = session.query('CALL db.indexes()')
          if result.columns.include?(:description)
            v3_indexes(result)
          else
            v4_indexes(result)
          end
        end

        def v3_indexes(result)
          result.reject do |row|
            # These indexes are created automagically when the corresponding constraints are created
            row.type == 'node_unique_property'
          end.map(&:description)
        end

        def v4_indexes(result)
          result.reject do |row|
            # These indexes are created automagically when the corresponding constraints are created
            row.uniqueness == 'UNIQUE'
          end.map(&method(:description))
        end

        def description(row)
          "INDEX FOR (n:#{row.labelsOrTypes.first}) ON (#{row.properties.map{|prop| "n.#{prop}"}.join(', ')})"
        end

        def drop_and_create_queries(existing, specified, remove_missing)
          [].tap do |queries|
            if remove_missing
              (existing - specified).each { |description| queries << "DROP #{description}" }
            end

            (specified - existing).each { |description| queries << "CREATE #{description}" }
          end
        end
      end
    end
  end
end
