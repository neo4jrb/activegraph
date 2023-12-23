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
        properties = properties.map { |p| "l.#{p}" }
        schema_query("CREATE INDEX FOR (l:`#{@name}`) ON (#{properties.join('.')})")
      end

      def drop_index(property, options = {})
        validate_index_options!(options)
        schema_query("SHOW INDEXES YIELD * WHERE labelsOrTypes = $labels AND properties = $properties",
                     labels: [@name], properties: [property]).each do |record|
          schema_query("DROP INDEX #{record[:name]}")
        end
      end

      # Creates a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = ActiveGraph::Label.create(:person)
      #   label.create_constraint(:name, {type: :unique})
      #
      def create_constraint(property, type: :key)
        schema_query(
          "CREATE CONSTRAINT #{constraint_name(property, type:)} FOR #{pattern("n:`#{name}`")} REQUIRE n.`#{property}` IS #{constraint_type(type:)}"
        )
      end

      # Drops a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = ActiveGraph::Label.create(:person)
      #   label.create_constraint(:name, {type: :unique})
      #   label.drop_constraint(:name, {type: :unique})
      #
      def drop_constraint(property, type: :key)
        schema_query("DROP CONSTRAINT #{constraint_name(property, type:)} IF EXISTS")
      end

      def drop_uniqueness_constraint(property, options = {})
        drop_constraint(property, type: :unique)
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
            ActiveGraph::Base.query("DROP INDEX #{definition[:name]}") unless definition[:owningConstraint]
          end
        end

        def drop_constraints
          result = ActiveGraph::Base.read_transaction do |tx|
            tx.run('SHOW CONSTRAINTS YIELD *').to_a
          end
          ActiveGraph::Base.write_transaction do |tx|
            result.each do |record|
              tx.run("DROP CONSTRAINT `#{record[:name]}`")
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

      def constraint_type(type:)
        case symnolic_type(type:)
        when :key
          "#{element_type} KEY"
        when :unique
          "UNIQUE"
        when :not_null
          "UNIQUE"
        else
          ":: #{type.to_s.upcase}"
        end
      end

      def symnolic_type(type:)
        type == :key && !ActiveGraph::Base.enterprise? ? :unique : type
      end

      def constraint_name(property, type:)
        "`#{element_type}_#{name}##{property}_#{symnolic_type(type:)}`"
      end
    end
  end
end
