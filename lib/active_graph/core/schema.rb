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
        raw_indexes.reject(&method(:constraint_owned?)).map do |row|
          definition(row, version?('<4') ? :index_cypher_v3 : :index_cypher)
            .merge(type: row[:type].to_sym, state: row[:state].to_sym)
        end
      end

      def constraints
        if version?('<4.3')
          raw_indexes.select(&method(:constraint_owned?))
        else
          raw_constraints.select(&method(:constraint_filter))
        end.map { |row| definition(row, :constraint_cypher).merge(type: :uniqueness) }
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

      def constraint_owned?(record)
        FILTER[major]&.then { |(key, value)| record[key] == value } || record[:owningConstraint]
      end

      def major
        @major ||= version.segments.first
      end

      def constraint_filter(record)
        %w[UNIQUENESS RELATIONSHIP_PROPERTY_EXISTENCE NODE_PROPERTY_EXISTENCE NODE_KEY].include?(record[:type])
      end

      def index_cypher_v3(label, properties)
        "INDEX ON :#{label}#{com_sep(properties, nil)}"
      end

      def index_cypher(label, properties)
        "INDEX FOR (n:#{label}) ON #{com_sep(properties)}"
      end

      def constraint_cypher(label, properties)
        "CONSTRAINT ON (n:#{label}) ASSERT #{com_sep(properties)} IS UNIQUE"
      end

      def com_sep(properties, prefix = 'n.')
        "(#{properties.map { |prop| "#{prefix}#{prop}" }.join(', ')})"
      end

      def definition(row, template)
        { label: label(row), properties: properties(row), name: row[:name],
          create_statement: row[:createStatement] || send(template,label(row), row[:properties]) }
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
