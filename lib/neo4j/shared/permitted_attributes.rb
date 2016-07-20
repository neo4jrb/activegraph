module Neo4j::Shared
  module PermittedAttributes
    extend ActiveSupport::Concern
    include ActiveModel::ForbiddenAttributesProtection

    def process_attributes(attributes)
      attributes = sanitize_for_mass_assignment(attributes)
      super(attributes)
    end

    def attributes=(attributes)
      attributes = sanitize_for_mass_assignment(attributes)
      super(attributes)
    end

    protected

    def sanitize_for_mass_assignment(attributes)
      attributes = super(attributes)
      attributes.respond_to?(:symbolize_keys) ? attributes.symbolize_keys : attributes
    end
  end
end
