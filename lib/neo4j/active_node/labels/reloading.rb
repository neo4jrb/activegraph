module Neo4j::ActiveNode::Labels
  module Reloading
    extend ActiveSupport::Concern

    MODELS_TO_RELOAD = []

    def self.reload_models!
      MODELS_TO_RELOAD.each(&:constantize)
      MODELS_TO_RELOAD.clear
    end

    module ClassMethods
      def before_remove_const
        associations.each_value(&:queue_model_refresh!)
        MODELS_FOR_LABELS_CACHE.clear
        WRAPPED_CLASSES.each { |c| MODELS_TO_RELOAD << c.name }
        WRAPPED_CLASSES.clear
      end
    end
  end
end
