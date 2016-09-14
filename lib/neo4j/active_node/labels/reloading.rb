module Neo4j::ActiveNode::Labels
  module Reloading
    extend ActiveSupport::Concern

    MODELS_TO_RELOAD = []

    def self.reload_models!
      Neo4j::ActiveNode::Labels::WRAPPED_CLASSES.clear
      Neo4j::ActiveNode::Labels.clear_wrapped_models
    end
  end
end
