require 'active_support/inflector'

class Neo4j::Node
  # The wrapping process is what transforms a raw CypherNode or EmbeddedNode from Neo4j::Core into a healthy ActiveNode (or ActiveRel) object.
  module Wrapper
    # this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects
    def wrapper
      found_class = class_to_wrap
      return self if not found_class

      found_class.new.tap do |wrapped_node|
        wrapped_node.init_on_load(self, self.props)
      end
    end

    def class_to_wrap
      load_classes_from_labels

      named_class || ::Neo4j::ActiveNode::Labels.model_for_labels(labels)
    end

    private

    def load_classes_from_labels
      labels.each { |label| Neo4j::Node::Wrapper.constant_for_label(label) }
    end

    # Only load classes once for performance
    CONSTANTS_FOR_LABELS_CACHE = ActiveSupport::Cache::MemoryStore.new

    def self.constant_for_label(label)
      @constants_for_labels ||= {}
      CONSTANTS_FOR_LABELS_CACHE.fetch(label.to_sym) do
        begin
          label.to_s.constantize
        rescue NameError
          nil
        end
      end
    end

    def named_class
      property = Neo4j::Config.class_name_property

      Neo4j::Node::Wrapper.constant_for_label(self.props[property]) if self.props.is_a?(Hash) && self.props.key?(property)
    end
  end
end
