module Neo4j
  module Relationships

    # This is the default wrapper class for the java neo4j relationship object.
    # It is possible to define your own wrapper classes for relationships, e.g. see Neo4j::NodeMixin#has_n
    # Wrapper class for a java org.neo4j.api.core.Relationship class
    #
    # :api: public
    class Relationship
      extend Neo4j::TransactionalMixin
      include Neo4j::RelationshipMixin
    end
  end
end