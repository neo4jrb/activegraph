module Neo4j::ActiveRel
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Shared::Property

    %w[to_node from_node].each do |direction|
      define_method("#{direction}") { instance_variable_get("@#{direction}") }
      define_method("#{direction}=") do |argument|
        raise FrozenRelError, 'Relationship start/end nodes cannot be changed once persisted' if self.persisted?
        instance_variable_set("@#{direction}", argument)
      end
    end

    alias_method :start_node, :from_node
    alias_method :end_node,   :to_node

    # @return [String] a string representing the relationship type that will be created
    def type
      self.class._type
    end

    def initialize(attributes = {}, options = {})
      super(attributes, options)

      send_props(@relationship_props) unless @relationship_props.nil?
    end

    module ClassMethods
      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_association_attributes!(attributes)
        attributes.keys.each_with_object({}) do |key, relationship_props|
          relationship_props[key] = attributes.delete(key) if [:from_node, :to_node].include?(key)
        end
      end

      %w[to_class from_class].each do |direction|
        define_method("#{direction}") { |argument| instance_variable_set("@#{direction}", argument) }
        define_method("_#{direction}") { instance_variable_get "@#{direction}" }
      end

      alias_method :start_class,  :from_class
      alias_method :end_class,    :to_class

      # @param type [String] sets the relationship type when creating relationships via this class
      def type(type = nil)
        @rel_type = type
      end

      # @return [String] a string representing the relationship type that will be created
      def _type
        @rel_type
      end

      def load_entity(id)
        Neo4j::Node.load(id)
      end
    end

    private

    def load_nodes(from_node = nil, to_node = nil)
      @from_node = RelatedNode.new(from_node)
      @to_node = RelatedNode.new(to_node)
    end
  end
end