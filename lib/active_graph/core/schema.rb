module ActiveGraph
  module Core
    module Schema
      def version
        read_transaction do
          # BTW: community / enterprise could be retrieved via `result.first.edition`
          query('CALL dbms.components()', {}, skip_instrumentation: true).first[:versions][0]
        end
      end

      def indexes
        read_transaction do
          result = query('CALL db.indexes()', {}, skip_instrumentation: true)

          result.map do |row|
            { type: row[:type].to_sym, label: label(result, row), properties: properties(row),
              state: row[:state].to_sym }
          end
        end
      end

      def constraints
        session do |session|
          session.read_transaction do |tx|
            tx.run('CALL db.indexes()')
                     .select(&method(v4?(tx.run('CALL db.indexes()')) ? :v4_filter : :v3_filter)).map do |row|
              { type: :uniqueness, label: label(tx.run('CALL db.indexes()'), row), properties: properties(row) }
            end
          end
        end
      end

      private

      def v4_filter(row)
        row[:uniqueness] == 'UNIQUE'
      end

      def v3_filter(row)
        row[:type] == 'node_unique_property'
      end

      def label(result, row)
        if v34?(result)
          row[:label]
        else
          (v4?(result) ? row[:labelsOrTypes] : row[:tokenNames]).first
        end.to_sym
      end

      def v4?(result)
        return @v4 unless @v4.nil?
        @v4 = result.keys.include?(:labelsOrTypes)
      end

      def v34?(result)
        return @v34 unless @v34.nil?
        @v34 = result.keys.include?(:label)
      end

      def properties(row)
        row[:properties].map(&:to_sym)
      end
    end
  end
end
