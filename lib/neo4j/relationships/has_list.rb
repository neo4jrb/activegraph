module Neo4j

  module Relationships
    class HasList
      include Enumerable
      extend Neo4j::TransactionalMixin

      def initialize(node, list_name, counter, &filter)
        @node = node
        @type = "_list_#{list_name}_#{node.neo_node_id}"
        if (counter)
          @counter_id = "_#{list_name}_size".to_sym
        end
      end

      def size
        @node[@counter_id] || 0
      end


      # called by the event handler
      def self.on_node_deleted(node) #:nodoc:
        # check if node is member of one or more lists
        node.lists{|list_item| list_item.prev.next = list_item.next; list_item.size -= 1}
      end

      # Appends one node to the end of the list
      #
      # :api: public
      def <<(other)
        # does node have a relationship ?
        if (@node.relationship?(@type))
          # get that relationship
          first = @node.relationships.outgoing(@type).first

          # delete this relationship
          first.delete
          old_first = first.other_node(@node)
          @node.relationships.outgoing(@type) << other
          other.relationships.outgoing(@type) << old_first
        else
          # the first node will be set
          @node.relationships.outgoing(@type) << other
        end
        if @counter_id
          @node[@counter_id] ||= 0
          @node[@counter_id] += 1
        end

        self
      end

      # Returns true if the list is empty                                                                        s
      #
      # :api: public
      def empty?
        !iterator.hasNext
      end

      def first
        return nil unless @node.relationship?(@type, :outgoing)
        @node.relationship(@type, :outgoing).end_node
      end

      def each
        iter = iterator
        while (iter.hasNext) do
          n = iter.next
          yield Neo4j.load(n.get_id)
        end
      end

      def iterator
        stop_evaluator = org.neo4j.api.core.StopEvaluator::END_OF_GRAPH
        traverser_order = org.neo4j.api.core.Traverser::Order::BREADTH_FIRST
        returnable_evaluator = org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE
        types_and_dirs = []
        types_and_dirs << RelationshipType.instance(@type)
        types_and_dirs << org.neo4j.api.core.Direction::OUTGOING
        @node.internal_node.traverse(traverser_order, stop_evaluator,  returnable_evaluator, types_and_dirs.to_java(:object)).iterator
      end


      transactional :empty?, :<<, :first
    end


  end


end