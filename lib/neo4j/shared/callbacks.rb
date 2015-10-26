module Neo4j
  module Shared
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods
        include ActiveModel::Callbacks
      end

      included do
        include ActiveModel::Validations::Callbacks
        # after_find is triggered by the `find` method defined in lib/neo4j/active_node/id_property.rb
        define_model_callbacks :initialize, :find, only: :after
        define_model_callbacks :save, :create, :update, :destroy, :touch
      end

      def initialize(args = nil)
        run_callbacks(:initialize) { super }
      end

      def destroy #:nodoc:
        tx = Neo4j::Transaction.new
        run_callbacks(:destroy) { super }
      rescue
        @_deleted = false
        @attributes = @attributes.dup
        tx.mark_failed
        raise
      ensure
        tx.close if tx
      end

      def touch #:nodoc:
        run_callbacks(:touch) { super }
      end

      # Allows you to perform a callback if a condition is not satisfied.
      # @param [Symbol] kind The callback type to execute unless the guard is true
      # @param [TrueClass,FalseClass] guard When this value is true, the block is yielded without executing callbacks.
      def conditional_callback(kind, guard)
        return yield if guard
        run_callbacks(kind) { yield }
      end

      private

      def create_or_update #:nodoc:
        run_callbacks(:save) { super }
      end

      def create_model #:nodoc:
        Neo4j::Transaction.run do
          run_callbacks(:create) { super }
        end
      end

      def update_model(*) #:nodoc:
        Neo4j::Transaction.run do
          run_callbacks(:update) { super }
        end
      end
    end
  end
end
