module Neo4j::ActiveRel
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Library::Property

    %w[inbound outbound].each do |direction|
      define_method("#{direction}") { instance_variable_get("@#{direction}") }
      define_method("#{direction}=") do |argument|
        raise FrozenRelError, "Relationship start/end nodes cannot be changed once persisted" if self.persisted?
        instance_variable_set("@#{direction}", argument)
      end
    end

    def rel_type
      self.class._rel_type
    end

    module ClassMethods

      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_relationship_attributes!(attributes)
        attributes.keys.inject({}) do |relationship_props, key|
          relationship_props[key] = attributes.delete(key) if key == :outbound || key == :inbound

          relationship_props
        end
      end

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

    def load_nodes(start_node=nil, end_node=nil)
      @inbound = RelatedNode.new(start_node)
      @outbound = RelatedNode.new(end_node)
    end

  end
end
