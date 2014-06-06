module Neo4j
  module ActiveRel
    module Initialize
      extend ActiveSupport::Concern
      include Neo4j::TypeConverters

      attr_reader :_persisted_rel

      # called when loading the node from the database
      # @param [Neo4j::Rel] persisted_node the rel this class wraps
      # @param [Hash] properties of the persisted rel.
      def init_on_load(persisted_rel, properties)
        @_persisted_rel = persisted_rel
        @changed_attributes && @changed_attributes.clear
        @attributes = attributes.merge(properties.stringify_keys)
        @attributes = convert_properties_to :ruby, @attributes
      end

      # Implements the Neo4j::Relationshio#wrapper method
      # so that we don't have to care if the node is wrapped or not.
      # @return self
      def wrapper
        self
      end
    end
  end
end
