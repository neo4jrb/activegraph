class Neo4j::ActiveNode::HasN::Association
  # Provides the interface needed to interact with the ActiveRel query factory.
  class RelWrapper
    include Neo4j::Shared::Cypher::RelIdentifiers
    include Neo4j::Shared::Cypher::CreateMethod

    attr_reader :type, :association
    attr_accessor :properties
    private :association
    alias_method :props_for_create, :properties

    def initialize(association, properties = {})
      @association = association
      @properties = properties
      @type = association.relationship_type(true)
      creates_unique(association.creates_unique_option) if association.unique?
    end

    def persisted?
      false
    end
  end
end
