# external neo4j dependencies
require 'neo4j/to_java'


module Neo4j
  module Rels

    # Traverse relationships of depth one from one node.
    # This object is returned when using the Neo4j::Rels which is included in the Neo4j::Node class.
    #
    class Traverser
      include Enumerable
      include ToJava

      def initialize(node, types, dir)
        @node = node
        if types.size > 1
          @types = types.inject([]) { |result, type| result << type_to_java(type) }.to_java(:'org.neo4j.graphdb.RelationshipType')
        elsif types.size == 1
          @type = type_to_java(types[0])
        end
        @dir = dir
      end

      def to_s
        if @type
          "#{self.class} [type: #{@type} dir:#{@dir}]"
        elsif @types
          "#{self.class} [types: #{@types.join(',')} dir:#{@dir}]"
        else
          "#{self.class} [types: ANY dir:#{@dir}]"
        end
      end

      def each
        iter = iterator
        while (iter.hasNext())
          rel = iter.next
          yield rel.wrapper if match_to_other?(rel)
        end
      end

      def empty?
        first == nil
      end

      def iterator
        if @types
          @node.get_relationships(@types).iterator
        elsif @type
          @node.get_relationships(@type, dir_to_java(@dir))
        else
          @node.get_relationships(dir_to_java(@dir))
        end
      end

      def match_to_other?(rel)
        if @to_other.nil?
          true
        elsif @dir == :outgoing
          rel._end_node == @to_other
        elsif @dir == :incoming
          rel._start_node == @to_other
        else
          rel._start_node == @to_other || rel._end_node == @to_other
        end
      end

      def to_other(to_other)
        @to_other = to_other
        self
      end

      def del
        each { |rel| rel.del }
      end

      def size
        [*self].size
      end

      def both
        @dir = :both
        self
      end

      def incoming
        raise "Not allowed calling incoming when finding several relationships types" if @types
        @dir = :incoming
        self
      end

      def outgoing
        raise "Not allowed calling outgoing when finding several relationships types" if @types
        @dir = :outgoing
        self
      end

    end

  end
end