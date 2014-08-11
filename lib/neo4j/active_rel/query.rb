module Neo4j::ActiveRel
  module Query
    extend ActiveSupport::Concern

    module ClassMethods
      include Enumerable

      # Returns the object with the specified neo4j id.
      # @param [String,Fixnum] id of node to find
      # @param [Neo4j::Session] session optional
      def find(id, session = self.neo4j_session)
        raise "Unknown argument #{id.class} in find method (expected String or Fixnum)" if not [String, Fixnum].include?(id.class)
        find_by_id(id, session)
      end

      def find_by_id(key, session = Neo4j::Session.current!)
        Neo4j::Relationship.load(key.to_i, session)
      end

      def where(args)
        @query = self._outbound_class.query_as(:n1).match("(n1:`#{self._outbound_class.name}`)-[r1:`#{self._rel_type}`]->(n2:`#{self._inbound_class.name}`)").where(Hash["r1" => args])
        return self
      end

      def each
        @query.pluck(:r1).each {|r| yield r }
      end

      def first
        @query.pluck(:r1).first
      end
    end
  end
end