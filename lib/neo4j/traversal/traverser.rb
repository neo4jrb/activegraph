module Neo4j

  module Traversal

    class Evaluator  #:nodoc:
      include org.neo4j.graphdb.traversal.Evaluator
      def initialize(&eval_block)
        @eval_block = eval_block
      end

      # Implements the Java Interface:
      #  evaluate(Path path)
      #  Evaluates a Path and returns an Evaluation containing information about whether or not to include it in the traversal result, i.e return it from the Traverser.
      def evaluate(path)
        ret = @eval_block.call(path)
        case ret
          when :exclude_and_continue then
            org.neo4j.graphdb.traversal.Evaluation::EXCLUDE_AND_CONTINUE
          when :exclude_and_prune then
            org.neo4j.graphdb.traversal.Evaluation::EXCLUDE_AND_PRUNE
          when :include_and_continue then
            org.neo4j.graphdb.traversal.Evaluation::INCLUDE_AND_CONTINUE
          when :include_and_prune then
            org.neo4j.graphdb.traversal.Evaluation::INCLUDE_AND_PRUNE
          else
            raise "Got #{ret}, only accept :exclude_and_continue,:exclude_and_prune,:include_and_continue and :include_and_prune"
        end
      end
    end

    class Traverser
      include Enumerable
      include ToJava
      include Neo4j::Paginate


      def initialize(from, type = nil, dir=nil)
        @from = from
        @depth = 1
        if type.nil? || dir.nil?
          @td = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new.breadth_first()
        else
          @type = type_to_java(type)
          @dir = dir_to_java(dir)
          @td = org.neo4j.kernel.impl.traversal.TraversalDescriptionImpl.new.breadth_first().relationships(@type, @dir)
        end
      end

      def eval_paths(&eval_path_block)
        @td = @td.evaluator(Evaluator.new(&eval_path_block))
        self
      end

      def unique(u = :node_global)
        case u
          when :node_global then
            # A node cannot be traversed more than once.
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::NODE_GLOBAL)
          when :node_path then
            # For each returned node there 's a unique path from the start node to it.
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::NODE_PATH)
          when :node_recent then
            # This is like NODE_GLOBAL, but only guarantees uniqueness among the most recent visited nodes, with a configurable count.
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::NODE_RECENT)
          when :none then
            # No restriction (the user will have to manage it).
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::NONE)
          when :rel_global then
            # A relationship cannot be traversed more than once, whereas nodes can.
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::RELATIONSHIP_GLOBAL)
          when :rel_path then
            # No restriction (the user will have to manage it).
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::RELATIONSHIP_PATH)
          when :rel_recent then
            # Same as for NODE_RECENT, but for relationships.
            @td = @td.uniqueness(org.neo4j.kernel.Uniqueness::RELATIONSHIP_RECENT)
          else
            raise "Got option for unique '#{u}' allowed: :node_global, :node_path, :node_recent, :none, :rel_global, :rel_path, :rel_recent"
        end
        self
      end

      def to_s
        "NodeTraverser [from: #{@from.neo_id} depth: #{@depth} type: #{@type} dir:#{@dir}"
      end


      def <<(other_node)
        new(other_node)
        self
      end

      # Returns an real ruby array.
      def to_ary
        self.to_a
      end

      def new(other_node)
        case @dir
          when org.neo4j.graphdb.Direction::OUTGOING
            @from.create_relationship_to(other_node, @type)
          when org.neo4j.graphdb.Direction::INCOMING
            other_node.create_relationship_to(@from, @type)
          else
            raise "Only allowed to create outgoing or incoming relationships (not #@dir)"
        end
      end

      def both(type)
        @type = type_to_java(type) if type
        @dir = dir_to_java(:both)
        @td = @td.relationships(type_to_java(type), @dir)
        self
      end

      def expander(&expander)
        @td = @td.expand(RelExpander.create_pair(&expander))
        self
      end

      def outgoing(type)
        @type = type_to_java(type) if type
        @dir = dir_to_java(:outgoing)
        @td = @td.relationships(type_to_java(type), @dir)
        self
      end

      def incoming(type)
        @type = type_to_java(type) if type
        @dir = dir_to_java(:incoming)
        @td = @td.relationships(type_to_java(type), @dir)
        self
      end

      def filter_method(name, &proc)
        # add method name
        singelton = class << self;
          self;
        end
        singelton.send(:define_method, name) { filter &proc }
        self
      end

      def functions_method(func, rule_node, rule_name)
        singelton = class << self;
          self;
        end
        singelton.send(:define_method, func.class.function_name) do |*args|
          function_id = args.empty? ? "_classname" : args[0]
          function = rule_node.find_function(rule_name, func.class.function_name, function_id)
          function.value(rule_node.rule_node, rule_name)
        end
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
        s = 0
        iterator.each { |_| s += 1 }
        s
      end

      alias_method :length, :size

      def [](index)
        each_with_index { |node, i| break node if index == i }
      end

      def empty?
        first == nil
      end

      def each
        @raw ? iterator.each { |i| yield i } : iterator.each { |i| yield i.wrapper }
      end

      # Same as #each but does not wrap each node in a Ruby class, yields the Java Neo4j Node instance instead.
      def each_raw
        iterator.each { |i| yield i }
      end

      # Returns an enumerable of relationships instead of nodes
      #
      def rels
        @traversal_result = :rels
        self
      end

      # If this is called then it will not wrap the nodes but instead return the raw Java Neo4j::Node objects when traversing
      #
      def raw
        @raw = true
        self
      end

      # Returns an enumerable of paths instead of nodes
      #
      def paths
        @traversal_result = :paths
        @raw = true
        self
      end

      def iterator
        unless @include_start_node
          if @filter_predicate
            @filter_predicate.include_start_node
          else
            @td = @td.filter(org.neo4j.kernel.Traversal.return_all_but_start_node)
          end
        end
        @td = @td.prune(org.neo4j.kernel.Traversal.pruneAfterDepth(@depth)) unless @depth == :all
        if @traversal_result == :rels
          @td.traverse(@from._java_node).relationships
        elsif @traversal_result == :paths
          @td.traverse(@from._java_node).iterator
        else
          @td.traverse(@from._java_node).nodes
        end

      end
    end
  end
end
