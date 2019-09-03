require 'benchmark'

module Neo4j
  module Migrations
    module Helpers
      extend ActiveSupport::Concern
      extend ActiveSupport::Autoload

      autoload :Schema
      autoload :IdProperty
      autoload :Relationships

      PROPERTY_ALREADY_DEFINED = 'Property `%{new_property}` is already defined in `%{label}`. '\
                                 'To overwrite, call `remove_property(:%{label}, :%{new_property})` before this method.'.freeze

      def remove_property(label, property)
        by_label(label).remove("n.#{property}").exec
      end

      def rename_property(label, old_property, new_property)
        fail Neo4j::MigrationError, format(PROPERTY_ALREADY_DEFINED, new_property: new_property, label: label) if property_exists?(label, new_property)
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

      def rename_label(old_label, new_label)
        by_label(old_label).set(n: new_label).remove(n: old_label).exec
      end

      def execute(string, params = {})
        ActiveBase.query(string, params).to_a
      end

      def say_with_time(message)
        say(message)
        result = nil
        time = Benchmark.measure { result = yield }
        say format('%.4fs', time.real), :subitem
        say("#{result} rows", :subitem) if result.is_a?(Integer)
        result
      end

      def say(message, subitem = false)
        output "#{subitem ? '   ->' : '--'} #{message}"
      end

      def query(*args)
        ActiveBase.new_query(*args)
      end

      protected

      def output(*string_format)
        puts format(*string_format) unless @silenced
      end

      def transactions?
        self.class.transaction?
      end

      private

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
