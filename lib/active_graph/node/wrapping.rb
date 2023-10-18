module ActiveGraph
  module Node
    module Wrapping
      # Only load classes once for performance
      CONSTANTS_FOR_LABELS_CACHE = {}

      class << self
        def wrapper(node)
          found_class = class_to_wrap(node.labels)
          return node unless found_class

          found_class.new.tap do |wrapped_node|
            wrapped_node.init_on_load(node, node.properties)
          end
        end

        def class_to_wrap(labels)
          load_classes_from_labels(labels)
          ActiveGraph::Node::Labels.model_for_labels(labels).tap do |model_class|
            populate_constants_for_labels_cache(model_class, labels)
          end
        end

        private

        def load_classes_from_labels(labels)
          labels.each { |label| constant_for_label(label) }
        end

        def constant_for_label(label)
          CONSTANTS_FOR_LABELS_CACHE[label] ||= constantized_label(label)
        end

        def constantized_label(label)
          "#{association_model_namespace}::#{label}".constantize
        rescue NameError, LoadError
          nil
        end

        def populate_constants_for_labels_cache(model_class, labels)
          labels.each do |label|
            CONSTANTS_FOR_LABELS_CACHE[label] ||= model_class
          end
        end

        def association_model_namespace
          ActiveGraph::Config.association_model_namespace_string
        end
      end
    end
  end
end
