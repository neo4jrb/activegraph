# external neo4j dependencies
require 'neo4j/to_java'
require 'neo4j/jars/core/neo4j-graph-algo-1.5.jar'
require 'neo4j/jars/core/neo4j-graph-matching-1.5.jar'

module Neo4j


  class Algo
    include Enumerable
    include ToJava

    class EstimateEvaluator #:nodoc
      include org.neo4j.graphalgo.EstimateEvaluator
      include ToJava

      def initialize(&evaluator)
        @evaluator = evaluator
      end

      # Implements T getCost(Node node, Node goal)
      # Estimate the weight of the remaining path from one node to another.
      def get_cost(node, goal)
        @evaluator.call(node, goal)
      end
    end

    class CostEvaluator #:nodoc
      include org.neo4j.graphalgo.CostEvaluator
      include ToJava

      def initialize(&evaluator)
        @evaluator = evaluator
      end

      # Implements the Java Method:   T getCost(Relationship relationship, Direction direction)
      # From the JavaDoc: <pre>
      # This is the general method for looking up costs for relationships.
      # This can do anything, like looking up a property or running some small calculation.
      # Parameters:
      # relationship -
      # direction - The direction in which the relationship is being evaluated, either Direction.INCOMING or Direction.OUTGOING.
      # Returns:
      # The cost for this edge/relationship
      # </pre>
      def get_cost(relationship, direction)
        @evaluator.call(relationship, dir_from_java(direction))
      end
    end

    def initialize(from, to, &factory_proc) #:nodoc:
      @from          = from
      @to            = to
      @factory_proc  = factory_proc
      @type_and_dirs = []

    end

    def _depth #:nodoc:
      @depth || java.lang.Integer::MAX_VALUE
    end

    def _expander #:nodoc:
      expander = @expander
      expander ||= @type_and_dirs.empty? ? org.neo4j.kernel.Traversal.expanderForAllTypes() : org.neo4j.kernel.Traversal.expanderForTypes(*@type_and_dirs)
      expander
    end

    def _cost_evaluator #:nodoc:
      raise "Algorithm requeries a cost evalulator, use the cost_evaluator to provide one" unless @cost_evaluator
      @cost_evaluator
    end

    def _estimate_evaluator #:nodoc:
      raise "Algorithm requeries a estimate evaluator, use the estimate_evaluator to provide one" unless @estimate_evaluator
      @estimate_evaluator
    end

    # Specifies which outgoing relationship should be traversed for the graph algorithm
    #
    # ==== Parameters
    # * rel :: relationship type (symbol)
    def outgoing(rel)
      @type_and_dirs << type_to_java(rel)
      @type_and_dirs << dir_to_java(:outgoing)
      self
    end

    # Specifies which incoming relationship should be traversed for the graph algorithm
    #
    # ==== Parameters
    # * rel :: relationship type (symbol)
    def incoming(rel)
      @type_and_dirs << type_to_java(rel)
      @type_and_dirs << dir_to_java(:incoming)
      self
    end

    # Specifies which relationship should be traversed for the graph algorithm
    #
    # ==== Example
    # The following:
    #
    #  Neo4j::Algo.shortest_path(@x,@y).expand{|node| node._rels(:outgoing, :friends)}
    #
    # Is the same as
    #  Neo4j::Algo.shortest_path(@x,@y).outgoing(:friends)
    #
    # ==== Parameters
    # * expander_proc :: a proc relationship type (symbol)
    def expand(&expander_proc)
      @expander = (Neo4j::Traversal::RelExpander.create_pair(&expander_proc))
      self
    end

    # If only a single path should be returned,
    # default for some algorithms, like shortest_path
    def single
      @single = true
      self
    end

    # See #single
    # Not sure if this method is useful
    def many
      @single = false
    end

    # The depth of the traversal
    # Notice not all algorithm uses this argument (aStar and dijkstra)
    def depth(depth)
      @depth = depth
      self
    end

    # Specifies a cost evaluator for the algorithm.
    # Only available for the aStar and dijkstra algorithms.
    #
    # ==== Example
    #  Neo4j::Algo.dijkstra(@x,@y).cost_evaluator{|rel,*| rel[:weight]}
    #
    def cost_evaluator(&cost_evaluator_proc)
      @cost_evaluator = CostEvaluator.new(&cost_evaluator_proc)
      self
    end

    # Specifies an evaluator that returns an (optimistic) estimation of the cost to get from the current node (in the traversal) to the end node.
    # Only available for the aStar algorithm.
    #
    # The provided proc estimate the weight of the remaining path from one node to another.
    # The proc takes two parameters:
    # * node :: the node to estimate the weight from.
    # * goal :: the node to estimate the weight to.
    #
    # The proc should return an estimation of the weight of the path from the first node to the second.
    #
    # ==== Example
    #
    #  Neo4j::Algo.a_star(@x,@y).cost_evaluator{...}.estimate_evaluator{|node,goal| some calucalation retuning a Float}
    #
    def estimate_evaluator(&estimate_evaluator_proc)
      @estimate_evaluator = EstimateEvaluator.new(&estimate_evaluator_proc)
      self
    end

    # Specifies that nodes should be returned from as result
    # See also #rels
    def nodes
      @path_finder_method = :nodes
      self
    end

    # Specifies that relationships should be returned from as result
    # See also #nodes
    #
    def rels
      @path_finder_method = :relationships
      self
    end


    # So that one can call directly method on the PathFinder result from an executed algorithm.
    def method_missing(m, *args, &block)
      execute_algo.send(m, *args)
    end

    def each(&block) #:nodoc:
      if @single && @path_finder_method
        execute_algo.send(@path_finder_method).each &block
      else
        traversal = execute_algo
        traversal.each &block if traversal
      end
    end

    def execute_algo #:nodoc:
      instance = self.instance_eval(&@factory_proc)
      if @single
        instance.find_single_path(@from._java_node, @to._java_node)
      else
        instance.find_all_paths(@from._java_node, @to._java_node)
      end
    end

    # Returns an instance of Neo4j::Algo which can find all available paths between two nodes.
    # These returned paths can contain loops (i.e. a node can occur more than once in any returned path).
    def self.all_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.all_paths(_expander, _depth) }
    end

    # See #all_paths, returns the first path found
    def self.all_path(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.all_paths(_expander, _depth) }.single
    end

    # Returns an instance of Neo4j::Algo which can find all simple paths between two nodes.
    # These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    def self.all_simple_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.all_simple_paths(_expander, _depth) }
    end

    # See #all_simple_paths, returns the first path found
    def self.all_simple_path(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.all_simple_paths(_expander, _depth) }.single
    end

    # Returns an instance of Neo4j::Algo which can find all shortest paths (that is paths with as short Path.length() as possible) between two nodes.
    # These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    def self.shortest_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.shortest_path(_expander, _depth) }
    end

    # See #shortest_paths, returns the first path found
    def self.shortest_path(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.shortest_path(_expander, _depth) }.single
    end

    # Returns an instance of Neo4j::Algo which uses the Dijkstra algorithm to find the cheapest path between two nodes.
    # The definition of "cheap" is the lowest possible cost to get from the start node to the end node, where the cost is returned from costEvaluator.
    # These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    # See http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm for more information.
    #
    # Example
    #
    #   Neo4j::Algo.dijkstra_path(node_a,node_b).cost_evaluator{|rel,*| rel[:weight]}.rels
    #
    def self.dijkstra_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.dijkstra(_expander, _cost_evaluator) }
    end

    # See #dijkstra_paths, returns the first path found
    #
    def self.dijkstra_path(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.dijkstra(_expander, _cost_evaluator) }.single
    end

    # Returns an instance of Neo4j::Algo which uses the A* algorithm to find the cheapest path between two nodes.
    # The definition of "cheap" is the lowest possible cost to get from the start node to the end node, where the cost is returned from lengthEvaluator and estimateEvaluator. These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    # See http://en.wikipedia.org/wiki/A*_search_algorithm for more information.
    #
    # Expacts an cost evaluator and estimate evaluator, see Algo#cost_evaluator and Algo#estimate_evaluator
    #
    # Example:
    #
    #  Neo4j::Algo.a_star_path(@x,@y).cost_evaluator{|rel,*| rel[:weight]}.estimate_evaluator{|node,goal| returns a float value}
    #
    def self.a_star_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.a_star(_expander, _cost_evaluator, _estimate_evaluator) }
    end

    # See #a_star_paths, returns the first path found
    #
    def self.a_star_path(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.a_star(_expander, _cost_evaluator, _estimate_evaluator) }.single
    end

    # Returns an instance of Neo4j::Algo can find all paths of a certain length(depth) between two nodes.
    # These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    # Expects setting the depth parameter (the lenghto of the path) by the Algo#depth method.
    #
    # Example:
    #
    #   Neo4j::Algo.with_length_paths(node_a,node_b).depth(2).each {|x| puts "Node #{x}"}
    #
    def self.with_length_paths(from,to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.paths_with_length(_expander, _depth) }
    end

    # See #with_length_paths, returns the first path found
    #
    def self.with_length_path(from,to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.paths_with_length(_expander, _depth) }.single
    end

  end
end
