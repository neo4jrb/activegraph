module Neo4j
  module Relationships

    # Provides dynamic property accessors.
    # Use this as a mixin if you do not want to declare what properties a Relationship has.
    # Wrapper class for a java org.neo4j.api.core.Relationship class
    #
    # :api: public
    class DynamicRelationship
      extend Neo4j::TransactionalMixin
      include Neo4j::RelationshipMixin
      include Neo4j::DynamicAccessorMixin
    end
  end
end