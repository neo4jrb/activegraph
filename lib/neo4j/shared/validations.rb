module Neo4j
  module Shared
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Validations
      # Implements the ActiveModel::Validation hook method.
      # @see http://rubydoc.info/docs/rails/ActiveModel/Validations:read_attribute_for_validation
      def read_attribute_for_validation(key)
        respond_to?(key) ? send(key) : self[key]
      end

      # The validation process on save can be skipped by passing false. The regular Model#save method is
      # replaced with this when the validations module is mixed in, which it is by default.
      # @param [Hash] options the options to create a message with.
      # @option options [true, false] :validate if false no validation will take place
      # @return [Boolean] true if it saved it successfully
      def save(options = {})
        result = perform_validations(options) ? super : false
        if !result
          Neo4j::Transaction.current.failure if Neo4j::Transaction.current
        end
        result
      end

      # @return [Boolean] true if valid
      def valid?(context = nil)
        context ||= (new_record? ? :create : :update)
        super(context)
        errors.empty?
      end

      private

      def perform_validations(options = {})
        perform_validation = case options
                             when Hash
                               options[:validate] != false
                             end

        if perform_validation
          valid?(options.is_a?(Hash) ? options[:context] : nil)
        else
          true
        end
      end
    end
  end
end
