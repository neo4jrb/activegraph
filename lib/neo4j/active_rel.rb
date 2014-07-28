module Neo4j

  # Makes Neo4j Relationships more or less act like ActiveRecord objects.
  module ActiveRel
    extend ActiveSupport::Concern

    include Neo4j::Library

    include Neo4j::ActiveRel::Initialize
    include Neo4j::ActiveRel::Persistence
    include Neo4j::ActiveRel::Property
    include Neo4j::ActiveRel::Callbacks
    include Neo4j::ActiveRel::Validations
    include Neo4j::ActiveRel::IdProperty

    def neo4j_obj
      _persisted_obj || raise("Tried to access native neo4j object on a non persisted object")
    end

    included do
      cache_class unless cached_class?
    end

    %w[inbound outbound].each do |direction|
      define_method("#{direction}") { instance_variable_get "@#{direction}" }
      define_method("#{direction}=") { |argument| instance_variable_set("@#{direction}", argument) }
    end

    def rel_type
      self.class._rel_type
    end

    module ClassMethods

      %w[inbound outbound].each do |direction|
        define_method("#{direction}_class") { |argument| instance_variable_set("@#{direction}_class", argument) }
        define_method("_#{direction}_class") { instance_variable_get "@#{direction}_class" }
      end

      def rel_type(type = nil)
        @rel_type = type
      end

      def _rel_type
        @rel_type
      end

      def load_entity(id)
        Neo4j::Node.load(id)
      end

    end

    private

    def load_nodes(start_node, end_node)
      @inbound = start_node
      @outbound = end_node
    end

  end
end