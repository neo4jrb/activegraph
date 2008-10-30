module Neo4j
  module Relations

    #
    # This is a private class holding the type of a relationship
    #
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