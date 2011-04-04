module Neo4j

  module Traversal

    class Traverser
      include Enumerable
      include ToJava
      include WillPaginate::Finders::Base


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


      def to_s
        "NodeTraverser [from: #{@from.neo_id} depth: #{@depth} type: #{@type} dir:#{@dir}"
      end


      def wp_query(options, pager, args, &block) #:nodoc:
        page = pager.current_page || 1
        per_page = pager.per_page
        to = per_page * page
        from = to - per_page
        i = 0
        res = []
        iterator.each do |node|
          res << node.wrapper if i >= from
          i += 1
          break if i >= to
        end
        pager.replace res
        pager.total_entries ||= count
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
            puts "FROM #{@from}/#{@from.class}, caller #{caller.inspect}"
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
        to_a.size
      end

      alias_method :length, :size

      def [](index)
        each_with_index { |node, i| break node if index == i }
      end

      def empty?
        first == nil
      end

      def each
        iterator.each { |i| yield i.wrapper }
      end

      # Same as #each but does not wrap each node in a Ruby class, yields the Java Neo4j Node instance instead.
      def each_raw
        iterator.each { |i| yield i }
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
        @td.traverse(@from._java_node).nodes
      end
    end
  end
end
