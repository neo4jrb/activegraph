module Neo4j
  module ActiveNode
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      included do
        # TODO add more support for callbacks
        [:save].each do |method|
          alias_method_chain method, :callbacks
        end

        extend ActiveModel::Callbacks

        define_model_callbacks :save
      end

      def save_with_callbacks
        run_callbacks :save do
          save_without_callbacks
        end
      end

    end
  end
end
