require 'active_support/inflector'
require 'active_graph/core/node'

wrapping_proc = proc do |node|
  found_class = ActiveGraph::NodeWrapping.class_to_wrap(node.labels)
  next node if not found_class

  found_class.new.tap do |wrapped_node|
    wrapped_node.init_on_load(node, node.props)
  end
end
Neo4j::Driver::Types::Node.wrapper_callback(wrapping_proc)

module ActiveGraph
  module NodeWrapping
    # Only load classes once for performance
    CONSTANTS_FOR_LABELS_CACHE = {}

    class << self
      def class_to_wrap(labels)
        load_classes_from_labels(labels)
        ActiveGraph::ActiveNode::Labels.model_for_labels(labels).tap do |model_class|
          populate_constants_for_labels_cache(model_class, labels)
        end
      end

      private

      def load_classes_from_labels(labels)
        labels.each { |label| constant_for_label(label) }
      end

      def constant_for_label(label)
        CONSTANTS_FOR_LABELS_CACHE[label] || CONSTANTS_FOR_LABELS_CACHE[label] = constantized_label(label)
      end

      def constantized_label(label)
        "#{association_model_namespace}::#{label}".constantize
      rescue NameError, LoadError
        nil
      end

      def populate_constants_for_labels_cache(model_class, labels)
        labels.each do |label|
          CONSTANTS_FOR_LABELS_CACHE[label] = model_class if CONSTANTS_FOR_LABELS_CACHE[label].nil?
        end
      end

      def association_model_namespace
        ActiveGraph::Config.association_model_namespace_string
      end
    end
  end
end
