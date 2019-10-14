module Neo4j
  module Core
    class Label
      attr_reader :name

      def initialize(name, session)
        @name = name
        @session = session
      end

      def create_index(property, options = {})
        validate_index_options!(options)
        properties = property.is_a?(Array) ? property.join(',') : property
        schema_query("CREATE INDEX ON :`#{@name}`(#{properties})")
      end

      def drop_index(property, options = {})
        validate_index_options!(options)
        schema_query("DROP INDEX ON :`#{@name}`(#{property})")
      end

      # Creates a neo4j constraint on a property
      # See http://docs.neo4j.org/chunked/stable/query-constraints.html
      # @example
      #   label = Neo4j::Label.create(:person, session)
      #   label.create_constraint(:name, {type: :unique}, session)
      #
      def create_constraint(property, constraints)
        cypher = case constraints[:type]
                 when :unique, :uniqueness
                   "CREATE CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
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
      #   label = Neo4j::Label.create(:person, session)
      #   label.create_constraint(:name, {type: :unique}, session)
      #   label.drop_constraint(:name, {type: :unique}, session)
      #
      def drop_constraint(property, constraint)
        cypher = case constraint[:type]
                 when :unique, :uniqueness
                   "DROP CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
                 else
                   fail "Not supported constraint #{constraint.inspect}"
                 end
        schema_query(cypher)
      end

      def drop_uniqueness_constraint(property, options = {})
        drop_constraint(property, options.merge(type: :unique))
      end

      def indexes
        @session.indexes.select do |definition|
          definition[:label] == @name.to_sym
        end
      end

      def self.indexes_for(session)
        session.indexes
      end

      def drop_indexes
        indexes.each do |definition|
          begin
            @session.query("DROP INDEX ON :`#{definition[:label]}`(#{definition[:properties][0]})")
          rescue Neo4j::Server::CypherResponse::ResponseError
            # This will error on each constraint. Ignore and continue.
            next
          end
        end
      end

      def self.drop_indexes_for(session)
        indexes_for(session).each do |definition|
          begin
            session.query("DROP INDEX ON :`#{definition[:label]}`(#{definition[:properties][0]})")
          rescue Neo4j::Server::CypherResponse::ResponseError
            # This will error on each constraint. Ignore and continue.
            next
          end
        end
      end

      def index?(property)
        indexes.any? { |definition| definition[:properties] == [property.to_sym] }
      end

      def constraints(_options = {})
        @session.constraints.select do |definition|
          definition[:label] == @name.to_sym
        end
      end

      def uniqueness_constraints(_options = {})
        constraints.select do |definition|
          definition[:type] == :uniqueness
        end
      end

      def drop_uniqueness_constraints
        uniqueness_constraints.each do |definition|
          @session.query("DROP CONSTRAINT ON (n:`#{definition[:label]}`) ASSERT n.`#{definition[:properties][0]}` IS UNIQUE")
        end
      end

      def self.drop_uniqueness_constraints_for(session)
        session.constraints.each do |definition|
          session.query("DROP CONSTRAINT ON (n:`#{definition[:label]}`) ASSERT n.`#{definition[:properties][0]}` IS UNIQUE")
        end
      end

      def constraint?(property)
        constraints.any? { |definition| definition[:properties] == [property.to_sym] }
      end

      def uniqueness_constraint?(property)
        uniqueness_constraints.include?([property])
      end

      def self.wait_for_schema_changes(session)
        schema_threads(session).map(&:join)
        set_schema_threads(session, [])
      end

      private

      # Store schema threads on the session so that we can easily wait for all
      # threads on a session regardless of label
      def schema_threads
        self.class.schema_threads(@session)
      end

      def schema_threads=(array)
        self.class.set_schema_threads(@session, array)
      end

      class << self
        def schema_threads(session)
          session.instance_variable_get('@_schema_threads') || []
        end

        def set_schema_threads(session, array)
          session.instance_variable_set('@_schema_threads', array)
        end
      end

      def schema_query(cypher)
        @session.transaction { |tx| tx.query(cypher, {}) }
      end

      def validate_index_options!(options)
        return unless options[:type] && options[:type] != :exact
        fail "Type #{options[:type]} is not supported"
      end
    end
  end
end
