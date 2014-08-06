module Neo4j::ActiveRel
  module Query

    extend ActiveSupport::Concern
    module ClassMethods

      def where(args)
        Neo4j::Relationship.load(self._outbound_class.query_as(:n1).match("(n1:`#{self._outbound_class.name}`)-[r1:`#{self._rel_type}`]->(n2:`#{self._inbound_class.name}`)").where(Hash["r1" => args]).pluck(:r1).first.neo_id)
      end
    end
  end
end