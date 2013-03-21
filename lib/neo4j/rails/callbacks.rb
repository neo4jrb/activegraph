module Neo4j
  module Rails
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern

      CALLBACKS = [
        :after_initialize, :before_validation, :after_validation,
        :before_create, :around_create, :after_create,
        :before_destroy, :around_destroy, :after_destroy,
        :before_save, :around_save, :after_save,
        :before_update, :around_update, :after_update,
        ].freeze

      included do
        extend ActiveModel::Callbacks

        define_model_callbacks :initialize, :only => :after
        define_model_callbacks :validation, :create, :save, :update, :destroy
      end

      def valid?(*) #:nodoc:
        run_callbacks(:validation) { super }
      end

      def destroy #:nodoc:
        run_callbacks(:destroy) { super }
      end

      private
      def create_or_update #:nodoc:
        run_callbacks(:save) { super }
      end

      def create #:nodoc:
        run_callbacks(:create)  { super }
      end

      def update_with_callbacks(*) #:nodoc:
        run_callbacks :update do
          update_without_callbacks
        end
      end

      def initialize_with_callbacks(*args, &block) #:nodoc:
        run_callbacks :initialize do
          initialize_without_callbacks(*args, &block)
        end
      end
    end
  end
end
