# Extension which finds the shortest path (in terms of number of links) between
# two nodes. Use something like this:
#
#   require 'neo4j/extensions/find_path'
#   node1.traverse.both(:knows).depth(:all).path_to(node2)
#   # => [node1, node42, node1234, node256, node2]
#
# This extension is still rather experimental. The algorithm is based on the one
# used in the Neo4j Java IMDB example.
#
# Martin Kleppmann, July 2009
module Neo4j
  module Relationships
    class NodeTraverser

      attr_accessor :predecessor_map, :other_traverser, :returnable_evaluator
      attr_writer :internal_node

      # Finds a path by starting a breadth-first traverser from each end and stopping as soon
      # as the two meet. Keeps a hash of current_node -> previous_node which allows us to
      # reconstruct the path that was taken once we meet. Returns an array with all of the
      # nodes constituting the path from +self+ to +other_node+ (inclusive), or +nil+ if no
      # path could be found.
      def path_to(other_node)
        return [] if other_node.internal_node.getId == self.internal_node.getId
        self.other_traverser = clone
        self.other_traverser.internal_node = other_node.internal_node
        self.other_traverser.other_traverser = self
        self.other_traverser.prepare_path_search
        self.other_traverser.swap_directions
        self.prepare_path_search

        while true # Advance the traversers in alternation
          break if self.search_for_path
          break if other_traverser.search_for_path
        end

        path = returnable_evaluator.found_path
        if !path && other_traverser.returnable_evaluator.found_path
          path = other_traverser.returnable_evaluator.found_path.reverse
        end
        path
      end

      # :nodoc:
      def path_traceback(end_node)
        # Reconstructs the chain of predecessors leading up to +end_node+. For internal use only.
        path = []
        while end_node = predecessor_map[end_node]
          path.unshift end_node
        end
        path
      end

      # :nodoc:
      def prepare_path_search
        self.returnable_evaluator = FindPathEvaluator.new(self, returnable_evaluator)
        self.predecessor_map = {Neo4j.load(internal_node.getId) => nil}
      end

      # :nodoc:
      def swap_directions
        @types_and_dirs = @types_and_dirs.map do |item|
          case item
          when org.neo4j.api.core.Direction::INCOMING
            org.neo4j.api.core.Direction::OUTGOING
          when org.neo4j.api.core.Direction::OUTGOING
            org.neo4j.api.core.Direction::INCOMING
          else
            item
          end
        end
      end

      # Advances this traverser's path search by one step. Returns +false+ if there is still
      # more to do and +true+ if finished (irrespective of whether or not a result was found).
      def search_for_path
        @path_iterator ||= iterator
        return true unless @path_iterator.hasNext
        node = @path_iterator.next
        !!returnable_evaluator.found_path # !! forces type to boolean
      end
    end


    class FindPathEvaluator
      include org.neo4j.api.core.ReturnableEvaluator

      attr_accessor :traverser, :original_evaluator, :found_path

      def initialize(traverser, original_evaluator)
        @traverser = traverser
        @original_evaluator = original_evaluator
      end

      # Called at each traversal position while searching for a path. Records the current node
      # and its predecessor (for generating the traceback) and checks whether the two traversers
      # have met.
      def isReturnableNode(traversal_position)
        return false unless original_evaluator.isReturnableNode(traversal_position)

        current  = Neo4j.load(traversal_position.current_node.getId)
        previous = Neo4j.load(traversal_position.previous_node.getId) unless traversal_position.previous_node.nil?
        traverser.predecessor_map[current] = previous

        if traverser.other_traverser.predecessor_map.include? current
          # Yay, found a path!
          @found_path = traverser.path_traceback(current)
          @found_path << current
          @found_path += traverser.other_traverser.path_traceback(current).reverse
        end

        true
      end
    end
  end
end
