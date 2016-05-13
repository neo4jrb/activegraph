module Neo4j
  module Migrations
    module Helpers
      extend ActiveSupport::Concern

      SCHEMA_CHANGE_IN_TRANSACTIONS = 'Can\'t drop %s inside a transaction.'\
                                      'Please add `disable_transactions!` in your migration file'.freeze

      CONSTRAINT_OR_INDEX_MISSING = 'No such %{type} for %{label}#%{property}'.freeze

      def remove_property(label, property)
        by_label(label).remove(n: property).exec
      end

      def rename_property(label, old_property, new_property)
        fail Neo4j::MigrationError, "Property `#{new_property}` is already defined in `#{label}`" if property_exists?(label, new_property)
        by_label(label).set("n.#{new_property} = n.#{old_property}")
                       .remove("n.#{old_property}").exec
      end

      def drop_nodes(label)
        query.match(n: label)
             .optional_match('(n)-[r]-()')
             .delete(:r, :n).exec
      end

      def add_labels(label, new_labels)
        by_label(label).set(n: new_labels).exec
      end

      def add_label(label, new_label)
        add_labels(label, [new_label])
      end

      def remove_labels(label, labels_to_remove)
        by_label(label).remove(n: labels_to_remove).exec
      end

      def remove_label(label, label_to_remove)
        remove_labels(label, [label_to_remove])
      end

      def drop_constraint(label, property)
        fail Neo4j::MigrationError, format(SCHEMA_CHANGE_IN_TRANSACTIONS, 'constraints') if transactions? || Neo4j::Transaction.current
        constraint = Neo4j::Schema::UniqueConstraintOperation.new(label, property)
        fail_missing_constraint_or_index!(:constraint, label, property) unless constraint.exist?
        constraint.drop!
      end

      def drop_index(label, property)
        fail Neo4j::MigrationError, format(SCHEMA_CHANGE_IN_TRANSACTIONS, 'indexes') if transactions? || Neo4j::Transaction.current
        index = Neo4j::Schema::ExactIndexOperation.new(label, property)
        fail_missing_constraint_or_index!(:index, label, property) unless index.exist?
        index.drop!
      end

      def execute(string, params = {})
        query(string, params).to_a
      end

      delegate :query, to: Neo4j::Session

      protected

      def transactions?
        self.class.transaction?
      end

      private

      def fail_missing_constraint_or_index!(type, label, property)
        fail Neo4j::MigrationError,
             format(CONSTRAINT_OR_INDEX_MISSING, type: type, label: label, property: property)
      end


      def property_exists?(label, property)
        by_label(label).where("EXISTS(n.#{property})").return(:n).any?
      end

      def by_label(label, options = {})
        symbol = options[:symbol] || :n
        query.match(symbol => label)
      end

      module ClassMethods
        def disable_transactions!
          @disable_transactions = true
        end

        def transaction?
          !@disable_transactions
        end
      end
    end
  end
end
