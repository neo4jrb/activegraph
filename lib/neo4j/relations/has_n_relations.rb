module Neo4j
  module Relations
    #
    # Enables traversal of nodes of a specific type that one node has.
    # Used for traversing relationship of a specific type.
    # Neo4j::NodeMixin can declare
    #
    class HasNRelations
      include Enumerable
      extend Neo4j::TransactionalMixin

      # TODO other_node_class not used ?
      def initialize(node, type, &filter)
        @node = node
        @type = RelationshipType.instance(type)
        @filter = filter
        @depth = 1
        @info = node.class.relations_info[type.to_sym]

        if @info[:outgoing]
          @direction = org.neo4j.api.core.Direction::OUTGOING
          @type = RelationshipType.instance(type)
        else
          @direction = org.neo4j.api.core.Direction::INCOMING
          other_class_type = @info[:type].to_s
          @type = RelationshipType.instance(other_class_type)
        end
      end


      def each
        stop = DepthStopEvaluator.new(@depth)
        traverser = @node.internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST,
          stop,
          org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE,
          @type,
          @direction)
        Neo4j::Transaction.run do
          iter = traverser.iterator
          while (iter.hasNext) do
            node = Neo4j.instance.load_node(iter.next)
            if !@filter.nil?
              res =  node.instance_eval(&@filter)
              next unless res
            end
            yield node
          end
        end
      end

      #
      # Creates a relationship instance between this and the other node.
      # If a class for the relationship has not been specified it will be of type DynamicRelation.
      # To set a relationship type see #Neo4j::relations
      #
      def new(other)
        from, to = @node, other
        from,to = to,from unless @info[:outgoing]

        r = Neo4j::Transaction.run {
          from.internal_node.createRelationshipTo(to.internal_node, @type)
        }
        from.class.relations_info[@type.name.to_sym][:relation].new(r)
      end


      #
      # Creates a relationship between this and the other node.
      # Returns self so that we can add several nodes like this:
      #
      #   n1 = Node.new # Node has declared having a friend type of relationship
      #   n2 = Node.new
      #   n3 = NodeMixin.new
      #
      #   n1 << n2 << n3
      #
      # This is the same as:
      #
      #   n1.friends.new(n2)
      #   n1.friends.new(n3)
      #
      def <<(other)
        from, to = @node, other
        from,to = to,from unless @info[:outgoing]

        r = from.internal_node.createRelationshipTo(to.internal_node, @type)
        from.class.new_relation(@type.name,r)
        from.class.fire_event(RelationshipAddedEvent.new(from, to, @type.name, r.getId()))
        other.class.fire_event(RelationshipAddedEvent.new(to, from, @type.name, r.getId()))
        self
      end


      #
      # Private class
      #
      class DepthStopEvaluator
        include org.neo4j.api.core.StopEvaluator

        def initialize(depth)
          @depth = depth
        end

        def isStopNode(pos)
          pos.depth >= @depth
        end
      end

      transactional :<<
      end

  end
end
