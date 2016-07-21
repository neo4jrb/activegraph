module Neo4j
  module Migrations
    module Helpers
      module Schema
        extend ActiveSupport::Concern
        MISSING_CONSTRAINT_OR_INDEX = 'No such %{type} for %{label}#%{property}'.freeze
        DUPLICATE_CONSTRAINT_OR_INDEX = 'Duplicate %{type} for %{label}#%{property}'.freeze

        def add_constraint(label, property, options = {})
          force = options[:force] || false
          constraint = Neo4j::Schema::UniqueConstraintOperation.new(label, property)
          fail_duplicate_constraint_or_index!(:constraint, label, property) if !force && constraint.exist?
          constraint.create!
        end

        def add_index(label, property, options = {})
          force = options[:force] || false
          index = Neo4j::Schema::ExactIndexOperation.new(label, property)
          fail_duplicate_constraint_or_index!(:index, label, property) if !force && index.exist?
          index.create!
        end

        def force_add_index(label, property)
          add_index(label, property)
        end

        def drop_constraint(label, property)
          constraint = Neo4j::Schema::UniqueConstraintOperation.new(label, property)
          fail_missing_constraint_or_index!(:constraint, label, property) unless constraint.exist?
          constraint.drop!
        end

        def drop_index(label, property)
          index = Neo4j::Schema::ExactIndexOperation.new(label, property)
          fail_missing_constraint_or_index!(:index, label, property) unless index.exist?
          index.drop!
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
