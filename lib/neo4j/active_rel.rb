module Neo4j

  # Makes Neo4j Relationships more or less act like ActiveRecord objects.
  module ActiveRel
    extend ActiveSupport::Concern

    include Neo4j::Shared
    include Neo4j::ActiveRel::Initialize
    include Neo4j::Shared::Identity
    include Neo4j::ActiveRel::Property
    include Neo4j::ActiveRel::Persistence
    include Neo4j::ActiveRel::Validations
    include Neo4j::ActiveRel::Callbacks
    include Neo4j::ActiveRel::Query

    class FrozenRelError < StandardError; end

    def initialize(*args)
      load_nodes
      super
    end

    def neo4j_obj
      _persisted_obj || raise("Tried to access native neo4j object on a non persisted object")
    end

    included do
      def self.inherited(other)
        super
      end

      cache_class unless cached_class?
    end
  end
end
