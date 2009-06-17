#
# This files contains common private classes that implements various Neo4j java interfaces.
# This classes are only used inside this Relationships module
#

module Neo4j
  module Relationships

    # Wrapper for org.neo4j.api.core.ReturnableEvaluator
    #
    # :api: private
    class ReturnableEvaluator
      include org.neo4j.api.core.ReturnableEvaluator

      def initialize(proc)
        @proc = proc
      end

      def isReturnableNode( traversal_position )
        # if the Proc takes one argument that we give it the traversal_position
        result = if @proc.arity == 1
          # wrap the traversal_position in the Neo4j.rb TraversalPostion object
          @proc.call TraversalPosition.new(traversal_position)
        else # otherwise we eval the proc in the context of the current node
          # do not include the start node
          return false if traversal_position.isStartNode()
          eval_context = Neo4j::load(traversal_position.currentNode.getId)
          eval_context.instance_eval(&@proc)
        end

        # java does not treat nil as false so we need to do instead
        (result)? true : false
      end
    end

    
    # Wrapper for the neo4j org.neo4j.api.core.StopEvalutor interface.
    # Used in the Neo4j Traversers.
    #
    # :api: private
    class DepthStopEvaluator
      include org.neo4j.api.core.StopEvaluator

      def initialize(depth)
        @depth = depth
      end

      def isStopNode(pos)
        pos.depth >= @depth
      end
    end


    # Wrapper for the Java org.neo4j.api.core.RelationshipType interface.
    # Each type is a singelton.
    # 
    # :api: private
    class RelationshipType
      include org.neo4j.api.core.RelationshipType

      @@names = {}

      def RelationshipType.instance(name)
        return @@names[name] if @@names.include?(name)
        @@names[name] = RelationshipType.new(name)
      end

      def to_s
        self.class.to_s + " name='#{@name}'"
      end

      def name
        @name
      end

      private

      def initialize(name)
        @name = name.to_s
        raise ArgumentError.new("Expect type of relationship to be a name of at least one character") if @name.empty?
      end

    end
  end
end