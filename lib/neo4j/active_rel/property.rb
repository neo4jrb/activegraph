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
      send_props(@relationship_props) unless @relationship_props.nil?
    end

    module ClassMethods
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

      def creates_unique
        @creates_unique = true
      end

      def creates_unique_rel
        warning = <<-WARNING
creates_unique_rel() is deprecated and will be removed from future releases,
use creates_unique() instead.
WARNING

        ActiveSupport::Deprecation.warn(warning, caller)

        creates_unique
      end

      def creates_unique?
        !!@creates_unique
      end
      alias_method :unique?, :creates_unique?
    end

    private

    def load_nodes(from_node = nil, to_node = nil)
      @from_node = RelatedNode.new(from_node)
      @to_node = RelatedNode.new(to_node)
    end
  end
end
