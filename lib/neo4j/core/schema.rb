module Neo4j
  module Core
    module Schema
      def version
        result = query('CALL dbms.components()', {}, skip_instrumentation: true)

        # BTW: community / enterprise could be retrieved via `result.first.edition`
        result.first.versions[0]
      end

      def indexes
        result = query('CALL db.indexes()', {}, skip_instrumentation: true)

        result.map do |row|
          label = (result.columns.include?(:labelsOrTypes) ? row.labelsOrTypes : row.tokenNames).first
          property = row.properties.first
          { type: row.type.to_sym, label: label(result, row), properties: properties(row), state: row.state.to_sym }
        end
      end

      def constraints
        result = query('CALL db.indexes()', {}, skip_instrumentation: true)

        result.select { |row| row.type == 'node_unique_property' || row.uniqueness == 'UNIQUE' }.map do |row|
          { type: :uniqueness, label: label(result, row), properties: properties(row) }
        end
      end

      def named_constraints
        query('CALL db.constraints()', {}, skip_instrumentation: true).tap do |result|
          result.columns.include?(:name) ? result.map(&:name) : []
        end
      end

      private

      def label(result, row)
        (result.columns.include?(:labelsOrTypes) ? row.labelsOrTypes : row.tokenNames).first.to_sym
      end

      def properties(row)
        row.properties.map(&:to_sym)
      end
    end
  end
end
