module ActiveGraph
  module Core
    module Schema
      FILTER = {
        3 => [:type, 'node_unique_property'],
        4 => [:uniqueness, 'UNIQUE'],
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
        if version?('<4.3')
          raw_indexes.select(&method(:index_filter))
        else
          raw_constraints.select(&method(:constraint_filter))
        end.map { |row| definition(row).merge(type: :uniqueness) }
      end

      private def raw_constraints
        read_transaction do
          query('SHOW CONSTRAINTS YIELD *', {}, skip_instrumentation: true).to_a
        end
      end

      def raw_indexes
        read_transaction do
          query(version?('<4.3') ? 'CALL db.indexes()' : 'SHOW INDEXES YIELD *', {}, skip_instrumentation: true)
            .reject { |row| row[:type] == 'LOOKUP' }.reject(&method(:index_filter))
        end
      end

      private

      def index_filter(record)
        FILTER[major]&.then { |(key, value)| record[key] == value } || record[:owningConstraint]
      end

      def major
        @major ||= version.segments.first
      end

      def constraint_filter(record)
        %w[UNIQUENESS RELATIONSHIP_PROPERTY_EXISTENCE NODE_PROPERTY_EXISTENCE NODE_KEY].include?(record[:type])
      end

      def definition(row)
        { label: label(row), properties: properties(row), name: row[:name],
          create_statement: version?('<4.3') ? row[:description] : row[:createStatement] }
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
