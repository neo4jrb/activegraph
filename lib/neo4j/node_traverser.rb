module Neo4j

  class PruneEvaluator
    include org.neo4j.graphdb.traversal.PruneEvaluator
    def initialize(proc)
      @proc = proc
    end

    def prune_after(path)
      @proc.call(path)
    end
  end


  class NodeTraverser
    include Enumerable

    def initialize(from, type, dir)
      @from = from
      @type = type_to_java(type)
      @dir = dir_to_java(dir)
      @depth = 1
      @td = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new.breadth_first().relationships(@type, @dir)
    end


    def type_to_java(type)
      org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
    end

    def dir_to_java(dir)
      case dir
        when :outgoing then org.neo4j.graphdb.Direction::OUTGOING
        when :both     then org.neo4j.graphdb.Direction::BOTH
        when :incoming then org.neo4j.graphdb.Direction::INCOMING
        else raise "unknown direction '#{dir}', expects :outgoing, :incoming or :both"
      end
    end

    def <<(other_node)
      raise "Only allowed to create outgoing relationships, please add it on the other node if you want to create an incoming relationship" unless @dir == org.neo4j.graphdb.Direction::OUTGOING
      @from.create_relationship_to(other_node, @type)
    end

    def outgoing(type)
      @td = @td.relationships(type_to_java(type), dir_to_java(:outgoing))
      self
    end

    def incoming(type)
      @td = @td.relationships(type_to_java(type), dir_to_java(:incoming))
      self
    end


    def prune(&block)
      @td = @td.prune(PruneEvaluator.new(block))
      self
    end

    def depth(d)
      @depth = d
      self
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next
      end
    end

    def iterator
      @td = @td.prune(org.neo4j.kernel.Traversal.pruneAfterDepth( @depth ) )
      iter = @td.traverse(@from).nodes.iterator
      iter.next if iter.hasNext
      # don't include the first node'
      iter
    end
  end

end