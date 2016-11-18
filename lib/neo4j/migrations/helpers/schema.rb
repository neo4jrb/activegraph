module Neo4j
  module Migrations
    module Helpers
      module Schema
        extend ActiveSupport::Concern
        MISSING_CONSTRAINT_OR_INDEX = 'No such %{type} for %{label}#%{property}'.freeze
        DUPLICATE_CONSTRAINT_OR_INDEX = 'Duplicate %{type} for %{label}#%{property}'.freeze

        def add_constraint(label, property, options = {})
          force = options[:force] || false
          type = options[:type] || :uniqueness
          label_object = ActiveBase.label_object(label)
          fail_duplicate_constraint_or_index!(:constraint, label, property) if !force && label_object.constraint?(property)
          label_object.create_constraint(property, type: type)
        end

        def add_index(label, property, options = {})
          force = options[:force] || false
          label_object = ActiveBase.label_object(label)
          fail_duplicate_constraint_or_index!(:index, label, property) if !force && label_object.index?(property)
          label_object.create_index(property)
        end

        def drop_constraint(label, property, options = {})
          type = options[:type] || :uniqueness
          label_object = ActiveBase.label_object(label)
          fail_missing_constraint_or_index!(:constraint, label, property) if !options[:force] && !label_object.constraint?(property)
          label_object.drop_constraint(property, type: type)
        end

        def drop_index(label, property, options = {})
          label_object = ActiveBase.label_object(label)
          fail_missing_constraint_or_index!(:index, label, property) if !options[:force] && !label_object.index?(property)
          label_object.drop_index(property)
        end

        protected

        def fail_missing_constraint_or_index!(type, label, property)
          fail Neo4j::MigrationError,
               format(MISSING_CONSTRAINT_OR_INDEX, type: type, label: label, property: property)
        end

        def fail_duplicate_constraint_or_index!(type, label, property)
          fail Neo4j::MigrationError,
               format(DUPLICATE_CONSTRAINT_OR_INDEX, type: type, label: label, property: property)
        end
      end
    end
  end
end
