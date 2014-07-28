module Neo4j::ActiveRel
  module IdProperty
    extend ActiveSupport::Concern

    module ClassMethods

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
    end
  end
end