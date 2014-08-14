module Neo4j::ActiveNode
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Library::Property

    module ClassMethods

      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_association_attributes!(attributes)
        attributes.keys.inject({}) do |association_props, key|
          association_props[key] = attributes.delete(key) if self.has_association?(key)

          association_props
        end
      end
    end
  end
end
