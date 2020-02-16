module Neo4j
  module Core
    class QueryBuilder
      attr_reader :queries

      Query = Struct.new(:cypher, :parameters, :pretty_cypher, :context)

      def initialize
        @queries = []
      end

      def append(*args)
        query = case args.map(&:class)
                when [String], [String, Hash]
                  Query.new(args[0], args[1] || {})
                when [::Neo4j::Core::Query]
                  args[0]
                else
                  fail ArgumentError, "Could not determine query from arguments: #{args.inspect}"
                end

        @queries << query
      end

      def query
        # `nil` drivers are just a workaround until
        # we phase out `Query` objects containing drivers
        Neo4j::Core::Query.new(driver: nil)
      end
    end
  end
end
