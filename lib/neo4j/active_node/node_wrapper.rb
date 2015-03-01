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

      named_class ||
        ::Neo4j::ActiveNode::Labels.model_for_labels(labels)
    end

    private

    def load_classes_from_labels
      labels.each { |label| label.to_s.constantize }
    rescue NameError
      nil
    end

    def named_class
      property = Neo4j::Config.class_name_property

      self.props[property].constantize if self.props.is_a?(Hash) && self.props.key?(property)
    end
  end
end
