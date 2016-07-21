module Neo4j::Shared
  module PermittedAttributes
    extend ActiveSupport::Concern
    include ActiveModel::ForbiddenAttributesProtection

    def process_attributes(attributes)
      attributes = sanitize_input_parameters(attributes)
      super(attributes)
    end

    def attributes=(attributes)
      attributes = sanitize_input_parameters(attributes)
      super(attributes)
    end

    protected

    # Check if an argument is a string or an ActionController::Parameters
    def hash_or_parameter?(args)
      args.is_a?(Hash) || args.respond_to?(:to_unsafe_h)
    end

    def sanitize_input_parameters(attributes)
      attributes = sanitize_for_mass_assignment(attributes)
      attributes.respond_to?(:symbolize_keys) ? attributes.symbolize_keys : attributes
    end
  end
end
