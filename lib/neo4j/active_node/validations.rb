module Neo4j
  module ActiveNode
    # This mixin replace the original save method and performs validation before the save.
    module Validations
      extend ActiveSupport::Concern

      include ActiveModel::Validations

      module ClassMethods
        def validates_uniqueness_of(*attr_names)
          validates_with UniquenessValidator, _merge_attributes(attr_names)
        end
      end

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
      def save(options={})
        result = perform_validations(options) ? super : false
        if !result
          Neo4j::Transaction.current.failure if Neo4j::Transaction.current
        end
        result
      end

      # @return [Boolean] true if valid
      def valid?(context = nil)
        context     ||= (new_record? ? :create : :update)
        super(context)
        errors.empty?
      end

      class UniquenessValidator < ::ActiveModel::EachValidator
        def initialize(options)
          super(options.reverse_merge(:case_sensitive => true))
          @klass = options[:class]
        end

        def validate_each(record, attribute, value)
          conditions = scope_conditions(record)

          # TODO: Added as find(:name => nil) throws error
          value = "" if value == nil

          if options[:case_sensitive]
            conditions[attribute] = value
          else
            conditions[attribute] = /^#{Regexp.escape(value.to_s)}$/i
          end

          # prevent that same object is returned 
          # TODO: add negative condtion to not return current record
          found = @klass.all(conditions).to_a
          found.delete(record)

          if found.count > 0
            record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
          end
        end

        def message(instance)
          super || "has already been taken"
        end

        def scope_conditions(instance)
          Array(options[:scope] || []).inject({}) do |conditions, key|
            conditions.merge(key => instance[key])
          end
        end
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
