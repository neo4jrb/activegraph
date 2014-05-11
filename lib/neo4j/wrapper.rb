class Neo4j::Node

  module Wrapper

    # this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects
    def wrapper
      wrappers = _class_wrappers
      if wrappers.empty?
        self
      else
        wrapper_classes = wrappers.map{|w| Neo4j::ActiveNode::Labels._wrapped_labels[w]}
        most_concrete_class = wrapper_classes.sort.first
        wrapped_node = most_concrete_class.new
        wrapped_node.init_on_load(self, self.props)
        wrapped_node
      end
    end

    def _class_wrappers
      labels.find_all do |label_name|
        Neo4j::ActiveNode::Labels._wrapped_labels[label_name].class == Class
      end
    end
  end

end
