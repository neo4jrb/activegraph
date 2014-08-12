
module Neo4j::ActiveRel
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Library::Property

    %w[to_node from_node].each do |direction|
      define_method("#{direction}") { instance_variable_get("@#{direction}") }
      define_method("#{direction}=") do |argument|
        raise FrozenRelError, "Relationship start/end nodes cannot be changed once persisted" if self.persisted?
        instance_variable_set("@#{direction}", argument)
      end
    end

    alias_method :start_node, :from_node
    alias_method :end_node,   :to_node

    def type
      self.class._type
    end

    module ClassMethods

      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_relationship_attributes!(attributes)
        attributes.keys.inject({}) do |relationship_props, key|
          relationship_props[key] = attributes.delete(key) if key == :from_node || key == :to_node

          relationship_props
        end
      end

      %w[to_class from_class].each do |direction|
        define_method("#{direction}") { |argument| instance_variable_set("@#{direction}", argument) }
        define_method("_#{direction}") { instance_variable_get "@#{direction}" }
      end

      alias_method :start_class,  :from_class
      alias_method :end_class,    :to_class

      def type(type = nil)
        @rel_type = type
      end

      def _type
        @rel_type
      end

      def load_entity(id)
        Neo4j::Node.load(id)
      end

    end

    private

    def load_nodes(start_node=nil, end_node=nil)
      @to = RelatedNode.new(start_node)
      @from = RelatedNode.new(end_node)
    end

  end
end
