module ActiveGraph
  module Core
    module Schema
      FILTER = {
        3 => [:type, 'node_unique_property'],
        4 => [:uniqueness, 'UNIQUE'],
        5 => [:type, 'UNIQUENESS'],
      }

      def version
        @version ||= read_transaction do
          # BTW: community / enterprise could be retrieved via `result.first.edition`
          query('CALL dbms.components()', {}, skip_instrumentation: true).first[:versions][0]
            .then(&Gem::Version.method(:new))
        end
      end

      def version?(requirement)
        Gem::Requirement.create(requirement).satisfied_by?(Gem::Version.new(version))
      end

      def indexes
        raw_indexes.map do |row|
          { type: row[:type].to_sym, label: label(row), properties: properties(row),
            state: row[:state].to_sym, name: row[:name] }
        end
      end

      def constraints
        send(db_proc? ? :raw_indexes : :raw_constraints).select(&method(:filter)).map do |row|
          { type: :uniqueness, label: label(row), properties: properties(row) }
        end
      end

      def raw_constraints
        read_transaction do
          query('SHOW CONSTRAINTS YIELD *', {}, skip_instrumentation: true)
            .filter { |row| row[:type] == 'UNIQUENESS' }
        end
      end

      def raw_indexes
        read_transaction do
          query(db_proc? ? 'CALL db.indexes()' : 'SHOW INDEXES YIELD *', {}, skip_instrumentation: true)
            .reject { |row| row[:type] == 'LOOKUP' }
        end
      end

      private

      def major
        @major ||= version.segments.first
      end

      def db_proc?
        version?('<4.3')
      end

      def filter(record)
        FILTER[major].then { |(key, value)| record[key] == value }
      end

      def label(row)
        row[version?('>=4') ? :labelsOrTypes : :tokenNames].first.to_sym
      end

      def properties(row)
        row[:properties].map(&:to_sym)
      end
    end
  end
end
