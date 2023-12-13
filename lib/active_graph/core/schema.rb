module ActiveGraph
  module Core
    module Schema
      def version
        Gem::Version.new(component[:versions][0])
      end

      def edition
        component[:edition]
      end

      def enterprise?
        edition == 'enterprise'
      end

      def version?(requirement)
        Gem::Requirement.create(requirement).satisfied_by?(version)
      end

      def indexes
        normalize(raw_indexes, *%i[type state])
      end

      def normalize(result, *extra)
        result.map do |row|
          definition(row, :index_cypher).merge(extra.to_h { |key| [key, row[key].to_sym] })
        end
      end

      def constraints
        raw_constraints.select(&method(:constraint_filter)).map { |row| definition(row, :constraint_cypher).merge(type: :uniqueness) }
      end

      private def raw_constraints
        read_transaction do
          query('SHOW CONSTRAINTS YIELD *', {}, skip_instrumentation: true).to_a
        end
      end

      def raw_indexes
        read_transaction do
          query('SHOW INDEXES YIELD *', {}, skip_instrumentation: true).reject { |row| row[:type] == 'LOOKUP' }
        end
      end

      def constraint_owned?(record)
        record[:owningConstraint]
      end

      private

      def component
        @component ||= read_transaction do
          query('CALL dbms.components()', {}, skip_instrumentation: true).first
        end
      end

      def major
        @major ||= version.segments.first
      end

      def constraint_filter(record)
        %w[UNIQUENESS RELATIONSHIP_UNIQUENESS RELATIONSHIP_PROPERTY_EXISTENCE NODE_PROPERTY_EXISTENCE NODE_KEY RELATIONSHIP_KEY].include?(record[:type])
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
          create_statement: row[:createStatement] || send(template, label(row), row[:properties]) }
      end

      def label(row)
        row[:labelsOrTypes].first.to_sym
      end

      def properties(row)
        row[:properties].map(&:to_sym)
      end
    end
  end
end
