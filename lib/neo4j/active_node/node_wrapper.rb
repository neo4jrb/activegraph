require 'active_support/inflector'

# wrapping_proc = Proc.new do (node)
#   # Copying code from Neo4j::Node::Wrapper#wrapper
#   # The other code should eventually be replaced
#   found_class = Neo4j::NodeWrapping.class_to_wrap(node)
#   return self if not found_class
#
#   found_class.new.tap do |wrapped_node|
#     wrapped_node.init_on_load(self, self.props)
#   end
# end
# require 'neo4j/core/node'
# Neo4j::Core::Node.wrapper_callback(wrapping_proc)


class Neo4j::Node
  # The wrapping process is what transforms a raw CypherNode or EmbeddedNode from Neo4j::Core into a healthy ActiveNode (or ActiveRel) object.
  module Wrapper
    # this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects
    def wrapper
      found_class = Neo4j::NodeWrapping.class_to_wrap(self)
      return self if not found_class

      found_class.new.tap do |wrapped_node|
        wrapped_node.init_on_load(self, self.props)
      end
    end
  end
end


module Neo4j
  module NodeWrapping
    def self.class_to_wrap(node)
      labels = node.labels
      labels.each { |label| constant_for_label(label) }

      (named_class(node) || ::Neo4j::ActiveNode::Labels.model_for_labels(labels)).tap do |model_class|
        labels.each do |label|
          CONSTANTS_FOR_LABELS_CACHE[label] = model_class if CONSTANTS_FOR_LABELS_CACHE[label].nil?
        end
      end
    end

    private

    # Only load classes once for performance
    CONSTANTS_FOR_LABELS_CACHE = {}

    def self.constant_for_label(label)
      CONSTANTS_FOR_LABELS_CACHE[label] || CONSTANTS_FOR_LABELS_CACHE[label] = constantized_label(label)
    end

    def self.constantized_label(label)
      association_model_namespace = Neo4j::Config.association_model_namespace_string

      "#{association_model_namespace}::#{label}".constantize
    rescue NameError
      nil
    end

    def self.named_class(node)
      property = Neo4j::Config.class_name_property

      constant_for_label(node.props[property]) if node.props.is_a?(Hash) && node.props.key?(property)
    end
  end
end
