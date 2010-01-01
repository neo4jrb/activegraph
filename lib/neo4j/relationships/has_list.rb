module Neo4j

  module Relationships

    # Provides appending and traversing nodes that are linked together in a list with
    # relationships to the next list item.
    #
    class HasList
      include Enumerable
      attr_reader :relationship_type

      def initialize(node, list_name, counter, cascade_delete, &filter)
        @node = node
        @relationship_type = "_list_#{list_name}_#{node.neo_id}"
        if (counter)
          @counter_id = "_#{list_name}_size".to_sym
        end
        @cascade_delete = cascade_delete if cascade_delete
      end

      def size
        @node[@counter_id] || 0
      end


      # called by the event handler
      def self.on_node_deleted(node) #:nodoc:
        # check if node is member of one or more lists
        node.lists{|list_item| list_item.prev.next = list_item.next if list_item.prev; list_item.size -= 1}
      end

      # Appends one node to the end of the list
      #
      # :api: public
      def <<(other)
        # does node have a relationship ?
        new_rel = []
        if (@node.rel?(@relationship_type))
          # get that relationship
          first = @node.rels.outgoing(@relationship_type).first

          # delete this relationship
          first.del
          old_first = first.other_node(@node)
          new_rel << @node.add_rel(@relationship_type, other)
          new_rel << other.add_rel(@relationship_type, old_first)
        else
          # the first node will be set
          new_rel << @node.add_rel(@relationship_type, other)
        end

        if @cascade_delete
          # the @node.neo_id is only used for cascade_delete_incoming since that node will be deleted when all the list items has been deleted.
          # if cascade_delete_outgoing all nodes will be deleted when the root node is deleted
          # if cascade_delete_incoming then the root node will be deleted when all root nodes' outgoing nodes are deleted
          new_rel.each {|rel| rel[@cascade_delete] = @node.neo_id}
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
        return nil unless @node.rel?(@relationship_type, :outgoing)
        @node.rel(@relationship_type, :outgoing).end_node
      end

      def each
        iter = iterator
        while (iter.hasNext) do
          n = iter.next
          yield Neo4j.load_node(n.get_id)
        end
      end

      def iterator
        stop_evaluator = org.neo4j.api.core.StopEvaluator::END_OF_GRAPH
        traverser_order = org.neo4j.api.core.Traverser::Order::BREADTH_FIRST
        returnable_evaluator = org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE
        types_and_dirs = []
        types_and_dirs << RelationshipType.instance(@relationship_type)
        types_and_dirs << org.neo4j.api.core.Direction::OUTGOING
        @node._java_node.traverse(traverser_order, stop_evaluator,  returnable_evaluator, types_and_dirs.to_java(:object)).iterator
      end

    end


  end


end