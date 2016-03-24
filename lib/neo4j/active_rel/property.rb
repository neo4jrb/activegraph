require 'neo4j/class_arguments'

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

    %w(start_node end_node).each do |direction|
      define_method("#{direction}_neo_id") { send(direction).neo_id if direction }
    end
    alias_method :from_node_neo_id, :start_node_neo_id
    alias_method :to_node_neo_id,   :end_node_neo_id

    # @return [String] a string representing the relationship type that will be created
    def type
      self.class.type
    end
    alias_method :rel_type, :type

    def initialize(attributes = nil)
      super(attributes)
    end

    def creates_unique_option
      self.class.creates_unique_option
    end

    module ClassMethods
      include Neo4j::Shared::Cypher::CreateMethod

      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_association_attributes!(attributes)
        return if attributes.blank?
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
          if !argument.nil?
            Neo4j::ClassArguments.validate_argument!(argument, direction)

            instance_variable_set("@#{direction}", argument)
          end

          self.instance_variable_get("@#{direction}")
        end

        define_method("_#{direction}") { instance_variable_get "@#{direction}" }
      end

      def valid_class_argument?(class_argument)
        [String, Symbol, FalseClass].include?(class_argument.class) ||
          (class_argument.is_a?(Array) && class_argument.all? { |c| [String, Symbol].include?(c.class) })
      end

      alias_method :start_class,  :from_class
      alias_method :end_class,    :to_class

      def load_entity(id)
        Neo4j::Node.load(id)
      end
    end

    private

    def load_nodes(from_node = nil, to_node = nil)
      @from_node = RelatedNode.new(from_node)
      @to_node = RelatedNode.new(to_node)
    end

    def inspect_attributes
      attributes.to_a
    end
  end
end
