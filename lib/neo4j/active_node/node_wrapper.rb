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
      Neo4j::ActiveNode::Labels.model_for_labels(labels).tap do |model_class|
        Neo4j::Node::Wrapper.populate_constants_for_labels_cache(model_class, labels)
      end
    end

    private

    def load_classes_from_labels
      labels.each { |label| Neo4j::Node::Wrapper.constant_for_label(label) }
    end

    # Only load classes once for performance
    CONSTANTS_FOR_LABELS_CACHE = {}

    def self.constant_for_label(label)
      CONSTANTS_FOR_LABELS_CACHE[label] || CONSTANTS_FOR_LABELS_CACHE[label] = constantized_label(label)
    end

    def self.constantized_label(label)
      "#{association_model_namespace}::#{label}".constantize
    rescue NameError
      nil
    end

    def self.populate_constants_for_labels_cache(model_class, labels)
      labels.each do |label|
        CONSTANTS_FOR_LABELS_CACHE[label] = model_class if CONSTANTS_FOR_LABELS_CACHE[label].nil?
      end
    end

    def self.association_model_namespace
      Neo4j::Config.association_model_namespace_string
    end
  end
end
