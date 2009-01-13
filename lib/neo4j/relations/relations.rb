#
# This files contains common private classes used by the Neo4j::Relations module
#

module Neo4j
  module Relations

    # Wrapper for the neo4j StopEvalutor interface.
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


    # Wrapper for the Java RelationshipType interface.
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
        raise ArgumentError.new("Expect type of relation to be a name of at least one character") if @name.empty?
      end

    end
  end
end