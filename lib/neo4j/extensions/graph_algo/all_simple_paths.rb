module Neo4j::GraphAlgo
  require 'neo4j/extensions/graph_algo/graph-algo-0.2-20090815.182816-1.jar'


  class ListOfAlternatingNodesAndRelationships  #:nodoc:
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

  class AllSimplePaths
    include Enumerable

    def initialize
      @types = []
      @direction = org.neo4j.api.core.Direction::OUTGOING
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
      @paths ||= org.neo4j.graphalgo.AllSimplePaths.new(@from._java_node, @to._java_node, @depth, @direction, @types.to_java(:"org.neo4j.api.core.RelationshipType"))
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
      types.each { |type| @types << Neo4j::Relationships::RelationshipType.instance(type)}
      @direction = org.neo4j.api.core.Direction::BOTH
      self
    end

    def outgoing(*types)
      types.each { |type| @types << Neo4j::Relationships::RelationshipType.instance(type)}
      @direction = org.neo4j.api.core.Direction::OUTGOING
      self
    end

    def incoming(*types)
      types.each { |type| @types << Neo4j::Relationships::RelationshipType.instance(type)}
      @direction = org.neo4j.api.core.Direction::INCOMING
      self
    end

  end

  def self.all_simple_paths
    # org.neo4j.api.core.Node node1, org.neo4j.api.core.Node node2, int maximumTotalDepth, org.neo4j.api.core.Direction relationshipDirection, org.neo4j.api.core.RelationshipType... relationshipTypes)
    AllSimplePaths.new
  end


end


