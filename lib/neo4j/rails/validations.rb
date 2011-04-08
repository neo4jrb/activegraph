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
        perform_validations(options) ? super : false
      end

      def valid?(context = nil, validated_nodes=nil)
        context     ||= (new_record? ? :create : :update)
        output      = super(context)
        output_rels = valid_relationships?(context, validated_nodes)
        errors.empty? && output && output_rels
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
