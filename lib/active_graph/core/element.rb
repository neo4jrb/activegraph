module ActiveGraph
  module Core
    class Element
      attr_reader :name
      delegate :version?, to: ActiveGraph::Base

      def initialize(name)
        @name = name
      end

      def create_index(*properties, **options)
        validate_index_options!(options)
        if version?('>=4.4')
          properties = properties.map { |p| "l.#{p}" }
          fragment = "FOR (l:`#{@name}`) ON"
        else
          fragment = "ON :`#{@name}`"
        end
        schema_query("CREATE INDEX #{fragment} (#{properties.join('.')})")
      end

      def drop_index(property, options = {})
        validate_index_options!(options)
        if version?('<4.3')
          schema_query("DROP INDEX ON :`#{@name}`(#{property})")
        else
          schema_query("SHOW INDEXES YIELD * WHERE labelsOrTypes = $labels AND properties = $properties",
                       labels: [@name], properties: [property]).each do |record|
            schema_query("DROP INDEX #{record[:name]}")
          end
        end
      end

      # Creates a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = ActiveGraph::Label.create(:person)
      #   label.create_constraint(:name, {type: :unique})
      #
      def create_constraint(property, constraints)
        cypher = case constraints[:type]
                 when :unique, :uniqueness
                   _for, _require = version?('>=4.4') ? %w[FOR REQUIRE] : %w[ON ASSERT]
                   "CREATE CONSTRAINT #{_for} (n:`#{name}`) #{_require} n.`#{property}` IS UNIQUE"
                 else
                   fail "Not supported constraint #{constraints.inspect} for property #{property} (expected :type => :unique)"
                 end
        schema_query(cypher)
      end

      def create_uniqueness_constraint(property, options = {})
        create_constraint(property, options.merge(type: :unique))
      end

      # Drops a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = ActiveGraph::Label.create(:person)
      #   label.create_constraint(:name, {type: :unique})
      #   label.drop_constraint(:name, {type: :unique})
      #
      def drop_constraint(property, constraint)
        return drop_constraint42(property, constraint) if version?('<4.3')
        type = case constraint[:type]
               when :unique, :uniqueness
                 'UNIQUENESS'
               when :exists
                 'NODE_PROPERTY_EXISTENCE'
               else
                 fail "Not supported constraint #{constraint.inspect}"
               end
        schema_query(
          'SHOW CONSTRAINTS YIELD * WHERE type = $type AND labelsOrTypes = $labels AND properties = $properties',
          type: type, labels: [name], properties: [property]).first[:name].tap do |constraint_name|
          schema_query("DROP CONSTRAINT #{constraint_name}")
        end
      end

      def drop_uniqueness_constraint(property, options = {})
        drop_constraint(property, options.merge(type: :unique))
      end

      def indexes
        self.class.indexes.select do |definition|
          definition[:label] == @name.to_sym
        end
      end

      def drop_indexes
        self.class.drop_indexes
      end

      def index?(property)
        indexes.any? { |definition| definition[:properties] == [property.to_sym] }
      end

      def constraints(_options = {})
        ActiveGraph::Base.constraints.select do |definition|
          definition[:label] == @name.to_sym
        end
      end

      def uniqueness_constraints(_options = {})
        constraints.select do |definition|
          definition[:type] == :uniqueness
        end
      end

      def constraint?(property)
        constraints.any? { |definition| definition[:properties] == [property.to_sym] }
      end

      def uniqueness_constraint?(property)
        uniqueness_constraints.include?([property])
      end

      private

      class << self
        def indexes
          ActiveGraph::Base.indexes
        end

        def drop_indexes
          indexes.each do |definition|
            begin
              ActiveGraph::Base.query(
                if definition[:name]
                  "DROP INDEX #{definition[:name]}"
                else
                  "DROP INDEX ON :`#{definition[:label]}`(#{definition[:properties][0]})"
                end)
            rescue Neo4j::Driver::Exceptions::DatabaseException
              # This will error on each constraint. Ignore and continue.
              next
            end
          end
        end

        def drop_constraints
          result = ActiveGraph::Base.read_transaction do |tx|
            tx.run(ActiveGraph::Base.version?('<4.3') ? 'CALL db.constraints' : 'SHOW CONSTRAINTS YIELD *').to_a
          end
          ActiveGraph::Base.write_transaction do |tx|
            result.each do |record|
              tx.run("DROP #{record.keys.include?(:name) ? "CONSTRAINT #{record[:name]}" : record[:description]}")
            end
          end
        end
      end

      def schema_query(cypher, **params)
        ActiveGraph::Base.query(cypher, params)
      end

      def validate_index_options!(options)
        return unless options[:type] && options[:type] != :exact
        fail "Type #{options[:type]} is not supported"
      end

      def drop_constraint42(property, constraint)
        cypher = case constraint[:type]
                 when :unique, :uniqueness
                   "n.`#{property}` IS UNIQUE"
                 when :exists
                   "exists(n.`#{property}`)"
                 else
                   fail "Not supported constraint #{constraint.inspect}"
                 end
        schema_query("DROP CONSTRAINT ON (n:`#{name}`) ASSERT #{cypher}")
      end
    end
  end
end
