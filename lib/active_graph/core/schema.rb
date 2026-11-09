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

      # The cypher-dsl dialect queries are rendered in: the `cypher_dialect` setting when present,
      # otherwise the dialect matching the connected server. For the Cypher activegraph generates only the
      # subquery syntax differs: `CALL { WITH n … }` before Neo4j 5.23, `CALL (n) { … }` from 5.23 on.
      # Without a driver, or while the server cannot be reached, the default dialect is used and nothing
      # is remembered, so the detection happens once a connection is possible.
      def dialect
        configured = ActiveGraph::Config[:cypher_dialect]
        return configured.to_sym if configured
        return CypherDSL::Renderer::Dialect::NEO4J_5_DEFAULT_CYPHER unless driver?

        @dialect ||= dialect_of(version)
      rescue Neo4j::Driver::Exceptions::ServiceUnavailableException, Neo4j::Driver::Exceptions::SessionExpiredException
        CypherDSL::Renderer::Dialect::NEO4J_5_DEFAULT_CYPHER
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

      def dialect_of(server_version)
        if server_version.segments.first < 5
          CypherDSL::Renderer::Dialect::NEO4J_4
        elsif server_version < Gem::Version.new('5.23')
          CypherDSL::Renderer::Dialect::NEO4J_5
        else
          CypherDSL::Renderer::Dialect::NEO4J_5_DEFAULT_CYPHER
        end
      end

      # Neo4j 2026.07+ renamed the uniqueness constraint types
      # (UNIQUENESS -> NODE_PROPERTY_UNIQUENESS, RELATIONSHIP_UNIQUENESS ->
      # RELATIONSHIP_PROPERTY_UNIQUENESS); accept both the old and new names.
      def constraint_filter(record)
        %w[UNIQUENESS NODE_PROPERTY_UNIQUENESS RELATIONSHIP_UNIQUENESS RELATIONSHIP_PROPERTY_UNIQUENESS
           RELATIONSHIP_PROPERTY_EXISTENCE NODE_PROPERTY_EXISTENCE NODE_KEY RELATIONSHIP_KEY].include?(record[:type])
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
