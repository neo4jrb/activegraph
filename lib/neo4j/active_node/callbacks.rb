module Neo4j
  module ActiveNode
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern

      module ClassMethods
        include ActiveModel::Callbacks
      end

      included do
        include ActiveModel::Validations::Callbacks

        define_model_callbacks :initialize, :find, :touch, :only => :after
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
    #  included do
    #    [:initialize, :create_or_update, :create, :update, :destroy].each do |method|
    #      alias_method_chain method, :callbacks
    #    end
    #
    #    extend ActiveModel::Callbacks
    #
    #    define_model_callbacks :initialize, :only => :after
    #    define_model_callbacks :validation, :save, :destroy, :update, :create
    #  end
    #
    #  private
    #
    #  def valid_with_callbacks?(*) #:nodoc:
    #    _run_validation_callbacks { valid_without_callbacks? }
    #  end
    #
    #  def destroy_with_callbacks(*args)
    #    run_callbacks :destroy do
    #      destroy_without_callbacks(*args)
    #    end
    #  end
    #
    #  def update_model_with_callbacks(*)
    #    run_callbacks :update do
    #      update_without_callbacks()
    #    end
    #  end
    #
    #  def create_model_with_callbacks
    #    run_callbacks :create do
    #      create_without_callbacks()
    #    end
    #  end
    #
    #  def create_or_update_with_callbacks(*) #:nodoc:
    #    run_callbacks :save do
    #      create_or_update_without_callbacks
    #    end
    #  end
    #
    #  def initialize_with_callbacks(*args, &block) #:nodoc:
    #    run_callbacks :initialize do
    #      initialize_without_callbacks(*args, &block)
    #    end
    #  end
    #
    #end
  end
end
