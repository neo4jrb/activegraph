module Neo4j
  #
  # Provides dynamic property accessors.
  # Use this as a mixin if you do not want to declare what properties a Relationship has.
  # Wrapper class for a java org.neo4j.api.core.Relationship class
  #
  class DynamicRelation
    extend Neo4j::TransactionalMixin
    include Neo4j::RelationMixin
    include Neo4j::DynamicAccessorMixin
    # TODO include dyanmic_accessors ?
  end

end