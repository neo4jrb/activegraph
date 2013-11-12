module Neo4j::Wrapper

  # this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects
  def wrapper
    found = labels.find do |label_name|
      Neo4j::ActiveNode::Labels._wrapped_labels[label_name].class == Class
    end

    if found
      wrapped_node = Neo4j::ActiveNode::Labels._wrapped_labels[found].new
      wrapped_node.init_on_load(self, self.props)
      wrapped_node
    else
      self
    end
  end

end
