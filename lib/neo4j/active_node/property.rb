module Neo4j::ActiveNode
  module Property
    extend ActiveSupport::Concern
    include Neo4j::Shared::Property

    def initialize(attributes = {}, options = {})
      super(attributes, options)
      send_props(@relationship_props) if _persisted_obj && !@relationship_props.nil?
    end

    module ClassMethods
      # Extracts keys from attributes hash which are relationships of the model
      # TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?
      def extract_association_attributes!(attributes)
        attributes.each_key do |key|
          if self.association?(key)
            @_association_attributes ||= {}
            @_association_attributes[key] = attributes.delete(key)
          end
        end
        # We want to return nil if this was not set, we do not want to return an empty array
        @_association_attributes
      end
    end
  end
end
