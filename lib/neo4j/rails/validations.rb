module Neo4j
  module Rails
    module Validations
      include ActiveModel::Validations

      def read_attribute_for_validation(key)
        respond_to?(key) ? send(key) : self[key]
      end

      # The validation process on save can be skipped by passing false. The regular Model#save method is
      # replaced with this when the validations module is mixed in, which it is by default.
      def save(options={})
        result = perform_validations(options) ? super : false
        if !result
          Neo4j::Rails::Transaction.fail if Neo4j::Rails::Transaction.running?
        end
        result
      end

      def valid?(context = nil)
        context     ||= (new_record? ? :create : :update)
        super(context)
        errors.empty?
      end

      private
      def perform_validations(options={})
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
