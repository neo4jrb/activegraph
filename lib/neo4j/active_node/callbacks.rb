module Neo4j
  module ActiveNode
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      included do
        # TODO add more support for callbacks
        [:save, :destroy, :update].each do |method|
          alias_method_chain method, :callbacks
        end

        extend ActiveModel::Callbacks

        define_model_callbacks :save, :destroy, :update
      end

      def save_with_callbacks(*args)
        run_callbacks :save do
          save_without_callbacks(*args)
        end
      end

      def destroy_with_callbacks(*args)
        run_callbacks :destroy do
          destroy_without_callbacks(*args)
        end
      end

      def update_with_callbacks(*) #:nodoc:
        _run_update_callbacks { update_without_callbacks }
      end

      def update_with_callbacks(*)
        run_callbacks :update do
          update_without_callbacks()
        end
      end


    end
  end
end
