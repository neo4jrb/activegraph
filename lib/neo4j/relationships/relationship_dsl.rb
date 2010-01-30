module Neo4j
  module Relationships

    # Enables finding relationships for one node
    #
    class RelationshipDSL
      include Enumerable
      attr_reader :node

      def initialize(node, direction = :outgoing, type = nil)
        @raw  = false
        @type = type
        @node = node

        case direction
          when :outgoing
            outgoing(type)
          when :incoming
            incoming(type)
          when :both
            both(type)
        end
      end

      # if raw == true then it will return raw Java object instead of wrapped JRuby object which can improve performance.
      def raw(raw = true)
        @raw = raw
        self
      end
      
      def outgoing(type = nil)
        @type = type
        @direction = org.neo4j.graphdb.Direction::OUTGOING
        self
      end

      def incoming(type = nil)
        @type = type
        @direction = org.neo4j.graphdb.Direction::INCOMING
        self
      end

      def filter(&filter_proc)
        @filter_proc = filter_proc
        self
      end

      def both(type = nil)
        @type = type
        @direction = org.neo4j.graphdb.Direction::BOTH
        self
      end


      # Creates a not declared relationship between this node and the given other_node with the given relationship type
      # Use this method if you do not want to declare the relationship with the class methods has_one or has_n.
      # Can be used at any time on any node.
      #
      # Only supports outgoing relationships.
      #
      # ==== Example
      #
      #  node1 = Neo4j::Node.new
      #  node2 = Neo4j::Node.new
      #  node1.rels.outgoing(:some_relationship_type) << node2  << node3
      #
      # ==== Returns
      # self - so that the << can be chained
      #
      # :api: public
      def <<(other_node)
        source, target = @node, other_node
        source, target = target, source if @direction == org.neo4j.graphdb.Direction::INCOMING
        source.add_rel(@type, target)
        self
      end

      def empty?
        !iterator.hasNext
      end

      # Return the first relationship or nil
      def first
        find {true}
      end

      #
      # Returns the relationship object to the other node.
      #
      def [](other_node)
        find {|r| r.end_node.neo_id == other_node.neo_id}
      end


      def each
        iter = iterator
        while (iter.hasNext) do
          rel = @raw ? iter.next : iter.next.wrapper
          next if @filter_proc && !rel.instance_eval(&@filter_proc)
          yield rel
        end
      end

      def nodes
        RelationshipsEnumeration.new(self, @raw)
      end

      def iterator
        # if type is nil then we traverse all relationship types of depth one
        return @node.getRelationships(@direction).iterator if @type.nil?
        return @node.getRelationships(org.neo4j.graphdb.DynamicRelationshipType.withName(@type.to_s), @direction).iterator unless @type.nil?
      end

      def to_s
        "RelationshipDSL [direction=#{@direction}, type=#{@type}]"
      end

      # Used from RelationshipDSL when traversing nodes instead of relationships.
      #
      class RelationshipsEnumeration #:nodoc:
        include Enumerable

        def initialize(relationships, raw)
          @relationships = relationships
          @raw = raw
        end

        def first
          find {true}
        end

        def empty?
          first.nil?
        end

        def each
          if @raw
            @relationships.each { |relationship| yield relationship.getOtherNode(@relationships.node) }
          else
            @relationships.each { |relationship| yield relationship.getOtherNode(@relationships.node).wrapper }
          end
        end


      end
    end

  end
end
