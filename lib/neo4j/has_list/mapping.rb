module Neo4j
  module HasList

    # Enables creating and traversal of nodes in a list.
    #
    # It uses the TimeLine http://api.neo4j.org/current/org/neo4j/index/timeline/Timeline.html,
    #
    # Includes the Enumerable Mixin.
    # The Neo4j::Mapping::ClassMethods::List#has_list  methods returns an object of this type.
    #
    # === Example, index same as size of list
    #
    #  class Person
    #     include Neo4j::NodeMixin
    #     has_list :feeds
    #  end
    #
    #  person = Person.new
    #  person.feeds << Neo4j::Node:new << Neo4j::Node.new
    #
    # === Example, using a custom index
    #
    #  class Person
    #     include Neo4j::NodeMixin
    #     has_list :feeds
    #  end
    #
    #  person = Person.new
    #  person.feeds[42] = (a = Neo4j::Node:new)
    #  person.feeds[1251] = Neo4j::Node.new
    #
    #  person.feeds[42] # => a
    #
    class Mapping
      include Enumerable
      include ToJava
      include WillPaginate::Finders::Base


      def initialize(indexer_for, node, name)
        @index = Neo4j.started_db.lucene.for_nodes("#{indexer_for.to_s.gsub('::', '_')}_#{name}-timeline", Neo4j::Config[:lucene][:exact])
        @time_line = org.neo4j.index.lucene.LuceneTimeline.new(Neo4j.started_db.graph, @index)
        @node      = node
        @name      = name
        self.size = 0 unless size
      end

      # returns the size of this list
      # notice in order to get correct result you must call the #remove method when an item is removed from the list
      def size
        @node["_list_size_#{@name}"]
      end

      # same as #size == 0
      def empty?
        size == 0
      end

      # returns the first node with index n
      def [](n)
        @time_line.getBetween(n, n).first
      end

      # returns all nodes with the given index n
      def all(n)
        @time_line.getBetween(n, n)
      end

      # returns the first node in the list or nil
      def first
        @time_line.getFirst()
      end

      # returns the last node in the list or nil
      def last
        @time_line.getLast
      end

      # adds a node to the list with the given index n
      def []=(n, other_node)
        @time_line.add(other_node, n)
        self.size = self.size + 1
      end

      # returns all the nodes between the given Range
      def between(range)
        @time_line.getBetween(range.first, range.end)
      end

      # removes one node from the list and decrases the size of the list,
      def remove(node)
        @index.remove(node, "timestamp")
        self.size = self.size - 1
      end

      # Required by the Enumerable mixin so that we can
      #
      # ==== Example
      #
      #  class Person
      #     include Neo4j::NodeMixin
      #     has_list :feeds
      #  end
      #
      #  person.feeds.each {|node| node}
      #
      def each
        @time_line.getBetween(java.lang.Long::MIN_VALUE,java.lang.Long::MAX_VALUE).iterator.each do |node|
          if @raw then
            yield node
          else
            yield node.wrapper
          end
        end
      end

      def wp_query(options, pager, args, &block) #:nodoc:
        @raw = true
        page = pager.current_page || 1
        to   = pager.per_page * page
        from = to - pager.per_page
        i    = 0
        res  = []
        each do |node|
          res << node.wrapper if i >= from
          i += 1
          break if i >= to
        end
        pager.replace res
        pager.total_entries ||= size
      end

      # If called then it will only return the raw java nodes and not the Ruby wrappers using the Neo4j::NodeMixin
      def raw
        @raw = true
      end

      def <<(other)
        @time_line.add(other._java_node, size)
        self.size = self.size + 1
        self
      end

      private
      def size=(size)
        @node["_list_size_#{@name}"] = size
      end
    end
  end
end
