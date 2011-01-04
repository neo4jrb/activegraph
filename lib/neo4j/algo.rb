module Neo4j


  class Algo
    include Enumerable
    include ToJava

    class CostEvaluator #:nodoc
      include org.neo4j.graphalgo.CostEvaluator
      include ToJava

      def initialize(&evaluator)
        @evaluator = evaluator
      end
      # Implements the Java Method:   T getCost(Relationship relationship, Direction direction)
      # From the JavaDoc: <pre>
      # This is the general method for looking up costs for relationships. This can do anything, like looking up a property or running some small calculation.
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
      @factory_proc   = factory_proc
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
      @expander = (RelExpander.create_pair(&expander_proc))
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

    # Specifies that nodes should be returned from as result (this is default)
    # See also #rels
    def nodes
      @path_finder_method = :nodes
      self
    end

    # Specifies that relationships should be returned from as result (this is default)
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
      if @single
        execute_algo.send(@path_finder_method || :nodes).each &block
      else
        execute_algo.each &block
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

    # Returns an algorithm which can find all available paths between two nodes. These returned paths can contain loops (i.e. a node can occur more than once in any returned path).
    def self.all_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.all_paths(_expander, _depth) }
    end

    # Returns an algorithm which can find all simple paths between two nodes. These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    def self.all_simple_paths(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.all_simple_paths(_expander, _depth) }
    end

    # Returns an algorithm which can find all shortest paths (that is paths with as short Path.length() as possible) between two nodes.
    # These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    def self.shortest_path(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.shortest_path(_expander, _depth) }.single
    end

    # Returns an PathFinder which uses the Dijkstra algorithm to find the cheapest path between two nodes.
    # The definition of "cheap" is the lowest possible cost to get from the start node to the end node, where the cost is returned from costEvaluator.
    # These returned paths cannot contain loops (i.e. a node cannot occur more than once in any returned path).
    # See http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm for more information.
    def self.dijkstra(from, to)
      Algo.new(from, to) { org.neo4j.graphalgo.GraphAlgoFactory.dijkstra(_expander, _cost_evaluator) }.single
    end
  end
end
#
#class Iterator
#  include java.lang.Iterable
##Iterator<T>	iterator()
##          Returns an iterator over a set of elements of type T.
#  def iterator
#
#  end
#end
