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
          { type: row.type.to_sym, label: label(result, row), properties: properties(row), state: row.state.to_sym }
        end
      end

      def constraints
        result = query('CALL db.indexes()', {}, skip_instrumentation: true)

        result.select(&method(v4?(result) ? :v4_filter : :v3_filter)).map do |row|
          { type: :uniqueness, label: label(result, row), properties: properties(row) }
        end
      end

      def named_constraints
        result = query('CALL db.constraints()', {}, skip_instrumentation: true)
        result.columns.include?(:name) ? result : []
      end

      private

      def v4_filter(row)
        row.uniqueness == 'UNIQUE'
      end

      def v3_filter(row)
        row.type == 'node_unique_property'
      end

      def label(result, row)
        (v34?(result) ? row.label : (v4?(result) ? row.labelsOrTypes : row.tokenNames).first).to_sym
      end

      def v4?(result)
        return @v4 unless @v4.nil?
        @v4 = result.columns.include?(:labelsOrTypes)
      end

      def v34?(result)
        return @v34 unless @v34.nil?
        @v34 = result.columns.include?(:label)
      end

      def properties(row)
        row.properties.map(&:to_sym)
      end
    end
  end
end
