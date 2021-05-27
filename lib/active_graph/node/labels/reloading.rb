module ActiveGraph::Node::Labels
  module Reloading
    extend ActiveSupport::Concern

    MODELS_TO_RELOAD = []

    def self.prepare_for_unload!
      # clear label caches
      ActiveGraph::Node::Labels.clear_wrapped_models

      WRAPPED_CLASSES.each do |c|
        # request refresh on any association proxies
        # that survive the reload
        c.associations.each_value(&:queue_model_refresh!)

        # save the class name to be reloaded later
        MODELS_TO_RELOAD << c.name
      end
      WRAPPED_CLASSES.clear
    end

    def self.reload_models!
      MODELS_TO_RELOAD.each(&:constantize)
      MODELS_TO_RELOAD.clear
    end

    module ClassMethods
      # NOTE: it seems that this method is not always called
      # by ActiveSupport, even though it probably should be.
      def before_remove_const
        associations.each_value(&:queue_model_refresh!)
        ActiveGraph::Node::Labels.clear_wrapped_models
        WRAPPED_CLASSES.each { |c| MODELS_TO_RELOAD << c.name }
        WRAPPED_CLASSES.clear
      end
    end
  end
end
