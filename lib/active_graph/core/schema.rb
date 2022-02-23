module ActiveGraph
  module Core
    module Schema
      def version
        # BTW: community / enterprise could be retrieved via `result.first.edition`
        query('CALL dbms.components()', {}, skip_instrumentation: true).first[:versions][0]
      end

      def indexes
        raw_indexes do |keys, result|
          result.map do |row|
            { type: row[:type].to_sym, label: label(keys, row), properties: properties(row),
              state: row[:state].to_sym }
          end
        end
      end

      def constraints
        raw_indexes do |keys, result|
          result.select(&method(v4?(keys) ? :v4_filter : :v3_filter)).map do |row|
            { type: :uniqueness, label: label(keys, row), properties: properties(row) }
          end
        end
      end

      def raw_indexes
        result = query('CALL db.indexes()', {}, skip_instrumentation: true)
        yield result.keys, result.reject { |row| row[:type] == 'LOOKUP' }
      end

      private

      def v4_filter(row)
        row[:uniqueness] == 'UNIQUE'
      end

      def v3_filter(row)
        row[:type] == 'node_unique_property'
      end

      def label(keys, row)
        if v34?(keys)
          row[:label]
        else
          (v4?(keys) ? row[:labelsOrTypes] : row[:tokenNames]).first
        end.to_sym
      end

      def v4?(keys)
        return @v4 unless @v4.nil?
        @v4 = keys.include?(:labelsOrTypes)
      end

      def v34?(keys)
        return @v34 unless @v34.nil?
        @v34 = keys.include?(:label)
      end

      def properties(row)
        row[:properties].map(&:to_sym)
      end
    end
  end
end
