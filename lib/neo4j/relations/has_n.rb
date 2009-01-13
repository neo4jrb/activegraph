module Neo4j
  module Relations

    # Enables traversal of nodes of a specific type that one node has.
    # Used for traversing relationship of a specific type.
    # Neo4j::NodeMixin can declare
    #
    class HasN
      include Enumerable
      extend Neo4j::TransactionalMixin

      # TODO other_node_class not used ?
      def initialize(node, type, &filter)
        @node = node
        @type = RelationshipType.instance(type)
        @filter = filter
        @stop_evaluator = DepthStopEvaluator.new(1)
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

      # Sets the depth of the traversal.
      # Default is 1 if not specified.
      #
      # ==== Example
      #  morpheus.friends.depth(:all).each { ... }
      #  morpheus.friends.depth(3).each { ... }
      #  
      # ==== Arguments
      # d<Fixnum,Symbol>:: the depth or :all if traversing to the end of the network.
      # ==== Return
      # self
      # 
      # :api: public
      def depth(d)
        if d == :all
          @stop_evaluator = org.neo4j.api.core.StopEvaluator::END_OF_GRAPH
        else
          @stop_evaluator = DepthStopEvaluator.new(d)
        end
        self
      end
      
      def each
        traverser = @node.internal_node.traverse(org.neo4j.api.core.Traverser::Order::BREADTH_FIRST,
          @stop_evaluator,
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


      # Creates a relationship instance between this and the other node.
      # If a class for the relationship has not been specified it will be of type DynamicRelation.
      #
      # :api: public
      def new(other)
        from, to = @node, other
        from,to = to,from unless @info[:outgoing]

        r = Neo4j::Transaction.run {
          from.internal_node.createRelationshipTo(to.internal_node, @type)
        }
        from.class.relations_info[@type.name.to_sym][:relation].new(r)
      end


      # Creates a relationship between this and the other node.
      #
      # ==== Example
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
      # ==== Returns
      # self
      #
      # :api: public
      def <<(other)
        from, to = @node, other
        from,to = to,from unless @info[:outgoing]

        r = from.internal_node.createRelationshipTo(to.internal_node, @type)
        from.class.new_relation(@type.name,r)
        from.class.fire_event(RelationshipAddedEvent.new(from, to, @type.name, r.getId()))
        other.class.fire_event(RelationshipAddedEvent.new(to, from, @type.name, r.getId()))
        self
      end


      transactional :<<
      end

  end
end
