module Neo4j
  module Migrations
    module Helpers
      def remove_property(label, property)
        by_label(label).remove(n: property)
                       .exec
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
        neo4j_label = Neo4j::Label.create(label)
        fail Neo4j::MigrationError,
             "No such constraint for #{label}\##{property}" unless neo4j_label.uniqueness_constraints[:property_keys].flatten.include?(property)
        neo4j_label.drop_constraint(property, type: :unique)
      end

      def drop_index(label, property)
        neo4j_label = Neo4j::Label.create(label)
        fail Neo4j::MigrationError,
             "No such index for #{label}\##{property}" unless neo4j_label.indexes[:property_keys].flatten.include?(property)
        neo4j_label.drop_index(property, type: :exact)
      end

      def execute(string, params = {})
        query(string, params).to_a
      end

      delegate :query, to: Neo4j::Session

      private

      def property_exists?(label, property)
        by_label(label).where("EXISTS(n.#{property})").return(:n).any?
      end

      def by_label(label, options = {})
        symbol = options[:symbol] || :n
        query.match(symbol => label)
      end
    end
  end
end
