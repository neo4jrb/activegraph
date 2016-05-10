module Neo4j
  module Migrations
    module Helpers
      def rename_property(label, old_property, new_property)
        by_label(label).where(n: {new_property => nil})
                       .set("n.#{new_property} = n.#{old_property}")
                       .remove("n.#{old_property}")
                       .exec
      end

      def drop_nodes(label)
        query.match("(n:`#{label}`)")
             .optional_match('(n)-[r]-()')
             .delete(:r, :n).exec
      end

      def add_labels(label, *labels)
        by_label(label).set("n:#{labels.join(':')}").exec
      end

      def remove_labels(label, *labels)
        by_label(label).remove("n:#{labels.join(':')}").exec
      end

      alias add_label add_labels
      alias remove_label remove_labels

      def remove_constraint(label, property)
        execute("DROP CONSTRAINT ON (n:`#{label}`) ASSERT n.#{property} IS UNIQUE")
      end

      def remove_index(label, property)
        execute("DROP INDEX ON :#{label}(#{property})")
      end

      def execute(string, params = {})
        query(string, params).to_a
      end

      private

      delegate :query, to: Neo4j::Session

      def by_label(label, symbol: :n)
        Neo4j::Session.query.match("(#{symbol}:`#{label}`)")
      end
    end
  end
end
