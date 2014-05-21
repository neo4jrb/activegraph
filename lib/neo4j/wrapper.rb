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

    def checked_labels_set
      @@_checked_labels_set ||= Set.new
    end

    def check_label(label_name)
      unless checked_labels_set.include?(label_name)
        load_class_from_label(label_name)
        # do this only once
        checked_labels_set.add(label_name)
      end
    end

    def load_class_from_label(label_name)
      begin
        label_name.to_s.split("::").inject(Kernel) {|container, name| container.const_get(name.to_s) }
      rescue NameError
        nil
      end
    end

    def _class_wrappers
      labels.find_all do |label_name|
        check_label(label_name)
        Neo4j::ActiveNode::Labels._wrapped_labels[label_name].class == Class
      end
    end
  end

end
