module Neo4j
  module ActiveNode
    # This mixin replace the original save method and performs validation before the save.
    module Validations
      extend ActiveSupport::Concern
      include Neo4j::Shared::Validations


      # @return [Boolean] true if valid
      def valid?(context = nil)
        context     ||= (new_record? ? :create : :update)
        super(context)
        errors.empty?
      end

      module ClassMethods
        def validates_uniqueness_of(*attr_names)
          validates_with UniquenessValidator, _merge_attributes(attr_names)
        end
      end


      class UniquenessValidator < ::ActiveModel::EachValidator
        def initialize(options)
          super(options.reverse_merge(:case_sensitive => true))
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
          found = record.class.where(conditions).to_a.select{|f| f.neo_id != record.neo_id}

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

    end
  end
end
