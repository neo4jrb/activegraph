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
          definition(row).merge(type: row[:type].to_sym, state: row[:state].to_sym)
        end
      end

      def constraints
        send(version?('<4.3') ? :raw_indexes : :raw_constraints).select(&method(:filter)).map do |row|
          definition(row).merge(type: :uniqueness)
        end
      end

      private def raw_constraints
        read_transaction do
          query('SHOW CONSTRAINTS YIELD *', {}, skip_instrumentation: true).to_a
        end
      end

      def raw_indexes
        read_transaction do
          query(version?('<4.3') ? 'CALL db.indexes()' : 'SHOW INDEXES YIELD *', {}, skip_instrumentation: true)
            .reject { |row| row[:type] == 'LOOKUP' }
        end
      end

      private

      def major
        @major ||= version.segments.first
      end

      def filter(record)
        FILTER[major].then { |(key, value)| record[key] == value }
      end

      def definition(row)
        { label: label(row), properties: properties(row), name: row[:name] }
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
