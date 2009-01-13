module Neo4j
  module Relations

    # Provides dynamic property accessors.
    # Use this as a mixin if you do not want to declare what properties a Relationship has.
    # Wrapper class for a java org.neo4j.api.core.Relationship class
    #
    # :api: public
    class DynamicRelation
      extend Neo4j::TransactionalMixin
      include Neo4j::RelationMixin
      include Neo4j::DynamicAccessorMixin
    end
  end
end