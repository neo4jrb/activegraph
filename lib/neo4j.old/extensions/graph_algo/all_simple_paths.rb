module Neo4j::GraphAlgo
  require 'neo4j/extensions/graph_algo/neo4j-graph-algo-0.3.jar'

                                                   
  class ListOfAlternatingNodesAndRelationships #:nodoc:
    include Enumerable

    def initialize(list)
      @list = list
    end

    def each
      iter = @list.iterator
      node = true
      while (iter.hasNext)
        id = iter.next.getId
        if (node)
          yield Neo4j.load_node(id)
        else
          yield Neo4j.load_rel(id)
        end
        node = !node
      end
    end
  end

  class ListOfNodes #:nodoc:
    include Enumerable

    def initialize(list)
      @list = list
    end

    def size
      @list.size
    end

    def each
      iter = @list.iterator
      while (iter.hasNext)
        n = iter.next
        yield Neo4j.load_node(n.getId)
      end
    end
  end

  # A Wrapper for some of the neo4j graphdb algorithms
  #
  # Currently only the AllSimplePaths is wrapped in Ruby.
  #
  # === Usage
  #
  #   found_nodes = GraphAlgo.all_simple_paths.from(node1).both(:knows).to(node7).depth(4).as_nodes
  #
  # === See also
  # * JavaDoc: http://components.neo4j.org/graph-algo/apidocs/org/neo4j/graphalgo/AllSimplePaths.html
  # * A complete example: http://github.com/andreasronge/neo4j/tree/master/examples/you_might_know/ 
  #
  class AllSimplePaths
    include Enumerable

    def initialize
      @types = []
      @direction = org.neo4j.graphdb.Direction::OUTGOING
    end

    def each
      if @as_nodes
        iter = paths.get_paths_as_nodes.iterator
        while (iter.has_next) do yield ListOfNodes.new(iter.next) end
      else
        iter = paths.get_paths.iterator
        while (iter.has_next) do yield ListOfAlternatingNodesAndRelationships.new(iter.next) end
      end
    end

    def as_nodes
      @as_nodes = true
      self
    end

    def size
      paths.get_paths_as_nodes.size
    end

    def paths
      @paths ||= org.neo4j.graphalgo.AllSimplePaths.new(@from._java_node, @to._java_node, @depth, @direction, @types.to_java(:"org.neo4j.graphdb.RelationshipType"))
    end

    def from(f)
      @from = f
      self
    end

    def to(t)
      @to = t
      self
    end

    def depth(d)
      @depth = d
      self
    end

    def both(*types)
      types.each { |type| @types << org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s) }
      @direction = org.neo4j.graphdb.Direction::BOTH
      self
    end

    def outgoing(*types)
      types.each { |type| @types << org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s) }
      @direction = org.neo4j.graphdb.Direction::OUTGOING
      self
    end

    def incoming(*types)
      types.each { |type| @types << org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s) }
      @direction = org.neo4j.graphdb.Direction::INCOMING
      self
    end

  end

  def self.all_simple_paths
    # org.neo4j.graphdb.Node node1, org.neo4j.graphdb.Node node2, int maximumTotalDepth, org.neo4j.graphdb.Direction relationshipDirection, org.neo4j.graphdb.RelationshipType... relationshipTypes)
    AllSimplePaths.new
  end


end


