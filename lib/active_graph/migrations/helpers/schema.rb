module ActiveGraph
  module Migrations
    module Helpers
      module Schema
        extend ActiveSupport::Concern
        MISSING_CONSTRAINT_OR_INDEX = 'No such %{type} for %{label}#%{property}'.freeze
        DUPLICATE_CONSTRAINT_OR_INDEX = 'Duplicate %{type} for %{label}#%{property}'.freeze

        def add_constraint(name, property, relationship: false, type: :key, force: false)
          element = ActiveGraph::Base.element(name, relationship:)
          if element.constraint?(property)
            if force
              element.drop_constraint(property, type:)
            else
              fail_duplicate_constraint_or_index!(:constraint, name, property)
            end
          end
          element.create_constraint(property, type:)
        end

        def add_index(label, property, options = {})
          force = options[:force] || false
          label_object = ActiveGraph::Base.label_object(label)
          if label_object.index?(property)
            if force
              label_object.drop_index(property)
            else
              fail_duplicate_constraint_or_index!(:index, label, property)
            end
          end
          label_object.create_index(property)
        end

        def drop_constraint(name, property, type: :key, relationship: false, force: false)
          element = ActiveGraph::Base.element(name, relationship:)
          fail_missing_constraint_or_index!(:constraint, name, property) unless force || element.constraint?(property)
          element.drop_constraint(property, type:)
        end

        def drop_index(label, property, options = {})
          label_object = ActiveGraph::Base.label_object(label)
          fail_missing_constraint_or_index!(:index, label, property) if !options[:force] && !label_object.index?(property)
          label_object.drop_index(property)
        end

        protected

        def fail_missing_constraint_or_index!(type, label, property)
          fail ActiveGraph::MigrationError,
               format(MISSING_CONSTRAINT_OR_INDEX, type: type, label: label, property: property)
        end

        def fail_duplicate_constraint_or_index!(type, label, property)
          fail ActiveGraph::MigrationError,
               format(DUPLICATE_CONSTRAINT_OR_INDEX, type: type, label: label, property: property)
        end
      end
    end
  end
end
