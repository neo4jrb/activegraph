module Neo4j
  module Core
    class CypherSession
      module Adaptors
        module Schema
          def version(session)
            result = query(session, 'CALL dbms.components()', {}, skip_instrumentation: true)

            # BTW: community / enterprise could be retrieved via `result.first.edition`
            result.first.versions[0]
          end

          def indexes(session)
            result = query(session, 'CALL db.indexes()', {}, skip_instrumentation: true)

            result.map do |row|
              label, property = row.description.match(/INDEX ON :([^\(]+)\(([^\)]+)\)/)[1, 2]
              {type: row.type.to_sym, label: label.to_sym, properties: [property.to_sym], state: row.state.to_sym}
            end
          end

          def constraints(session)
            result = query(session, 'CALL db.indexes()', {}, skip_instrumentation: true)

            result.select { |row| row.type == 'node_unique_property' }.map do |row|
              label, property = row.description.match(/INDEX ON :([^\(]+)\(([^\)]+)\)/)[1, 2]
              {type: :uniqueness, label: label.to_sym, properties: [property.to_sym]}
            end
          end
        end
      end
    end
  end
end
