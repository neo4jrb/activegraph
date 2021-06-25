module ActiveGraph
  module Core
    class QueryBuilder
      Query = Struct.new(:cypher, :parameters, :pretty_cypher, :context)

      def self.query(*args)
        case args.map(&:class)
        when [String], [String, Hash]
          Query.new(args[0], args[1] || {})
        when [::ActiveGraph::Core::Query]
          args[0]
        else
          fail ArgumentError, "Could not determine query from arguments: #{args.inspect}"
        end
      end
    end
  end
end
