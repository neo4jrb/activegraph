module Neo4j

  class PruneEvaluator  # :nodoc:
    include org.neo4j.graphdb.traversal.PruneEvaluator
    def initialize(proc)
      @proc = proc
    end

    def prune_after(path)
      @proc.call(path)
    end
  end

  class FilterPredicate # :nodoc:
    include org.neo4j.helpers.Predicate
    def initialize
      @procs = []
    end

    def add(proc)
      @procs << proc
    end

    def include_start_node
      @include_start_node = true
    end

    def accept(path)
      return false if @include_start_node && path.length == 0
      # find the first filter which returns false
      # if not found then we will accept this path
      @procs.find {|p| !p.call(path)}.nil?
    end
  end


  class NodeTraverser
    include Enumerable
    include ToJava

    def initialize(from, type = nil, dir=nil)
      @from  = from
      @depth = 1
      if type.nil? || dir.nil?
        @td    = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new.breadth_first()
      else
        @type  = type_to_java(type)
        @dir   = dir_to_java(dir)
        @td    = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new.breadth_first().relationships(@type, @dir)
      end
    end


    def to_s
      "NodeTraverser [from: #{@from.neo_id} depth: #{@depth} type: #{@type} dir:#{@dir}"
    end

    def <<(other_node)
      new(other_node)
      self
    end

    def new(other_node)
      raise "Only allowed to create outgoing relationships, please add it on the other node if you want to create an incoming relationship" unless @dir == org.neo4j.graphdb.Direction::OUTGOING
      @from.create_relationship_to(other_node, @type)
    end

    def both(type)
      @type  = type_to_java(type) if type
      @dir   = dir_to_java(:both)
      @td = @td.relationships(type_to_java(type), @dir)
      self
    end

    def outgoing(type)
      @type  = type_to_java(type) if type
      @dir   = dir_to_java(:outgoing)
      @td = @td.relationships(type_to_java(type), @dir)
      self
    end

    def incoming(type)
      @type  = type_to_java(type) if type
      @dir   = dir_to_java(:incoming)
      @td = @td.relationships(type_to_java(type), @dir)
      self
    end

    def filter_method(name, &proc)
      # add method name
      singelton = class << self; self; end
      singelton.send(:define_method, name) {filter &proc}
      self
    end

    def prune(&block)
      @td = @td.prune(PruneEvaluator.new(block))
      self
    end

    def filter(&block)
      # we keep a reference to filter predicate since only one filter is allowed and we might want to modify it
      @filter_predicate ||= FilterPredicate.new
      @filter_predicate.add(block)
      @td = @td.filter(@filter_predicate)
      self
    end

    # Sets depth, if :all then it will traverse any depth
    def depth(d)
      @depth = d
      self
    end

    def include_start_node
      @include_start_node = true
      self
    end

    def size
      [*self].size
    end

    def each
      iter = iterator
      while (iter.hasNext) do
        yield iter.next.wrapper
      end
    end

    def iterator
      unless @include_start_node
        if @filter_predicate
          @filter_predicate.include_start_node
        else
          @td = @td.filter(org.neo4j.kernel.Traversal.return_all_but_start_node)
        end
      end
      @td = @td.prune(org.neo4j.kernel.Traversal.pruneAfterDepth( @depth ) ) unless @depth == :all
      @td.traverse(@from).nodes.iterator
    end
  end

end