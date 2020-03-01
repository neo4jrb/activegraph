class ActiveGraph::Node::HasN::Association
  # Provides the interface needed to interact with the Relationship query factory.
  class RelWrapper
    include ActiveGraph::Shared::Cypher::RelIdentifiers
    include ActiveGraph::Shared::Cypher::CreateMethod

    attr_reader :type, :association
    attr_accessor :properties
    private :association
    alias props_for_create properties

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
