module Neo4j::ActiveRel
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Shared::Property

    %w(to_node from_node).each do |direction|
      define_method("#{direction}") { instance_variable_get("@#{direction}") }
      define_method("#{direction}=") do |argument|
        fail FrozenRelError, 'Relationship start/end nodes cannot be changed once persisted' if _persisted_obj
        instance_variable_set("@#{direction}", argument)
      end
    end

    alias_method :start_node, :from_node
    alias_method :end_node,   :to_node

    # @return [String] a string representing the relationship type that will be created
    def type
      self.class._type
    end

    def initialize(attributes = nil)
      super(attributes)
      send_props(@relationship_props) unless @relationship_props.nil?
    end

    module ClassMethods
      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_association_attributes!(attributes)
        {}.tap do |relationship_props|
          attributes.each_key do |key|
            relationship_props[key] = attributes.delete(key) if [:from_node, :to_node].include?(key)
          end
        end
      end

      def id_property_name
        false
      end

      %w(to_class from_class).each do |direction|
        define_method("#{direction}") do |argument = nil|
          return self.instance_variable_get("@#{direction}") if argument.nil?
          instance_variable_set("@#{direction}", argument)
        end

        define_method("_#{direction}") { instance_variable_get "@#{direction}" }
      end

      alias_method :start_class,  :from_class
      alias_method :end_class,    :to_class

      def load_entity(id)
        Neo4j::Node.load(id)
      end

      def creates_unique_rel
        @unique = true
      end

      def unique?
        !!@unique
      end
    end

    private

    def load_nodes(from_node = nil, to_node = nil)
      @from_node = RelatedNode.new(from_node)
      @to_node = RelatedNode.new(to_node)
    end
  end
end
