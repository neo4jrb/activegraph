module Neo4j
  module Shared
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods
        include ActiveModel::Callbacks
      end

      included do
        include ActiveModel::Validations::Callbacks
        define_model_callbacks :initialize, :find, only: :after
        define_model_callbacks :save, :create, :update, :destroy
      end

      def destroy #:nodoc:
        run_callbacks(:destroy) { super }
      end

      def touch(*) #:nodoc:
        run_callbacks(:touch) { super }
      end

      private

      def create_or_update #:nodoc:
        run_callbacks(:save) { super }
      end

      def create_model #:nodoc:
        run_callbacks(:create) { super }
      end

      def update_model(*) #:nodoc:
        run_callbacks(:update) { super }
      end
    end

  end
end
