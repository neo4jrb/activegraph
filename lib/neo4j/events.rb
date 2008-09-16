module Neo4j
  
  #
  # The base class of all Neo4j events
  #
  class Event
    attr_reader :node
    def initialize(node)
      @node = node
    end
    
    def to_s
      "Event #{self.class.to_s} on node #@node (#{@node.neo_node_id})"
    end
  end
  
  class PropertyChangedEvent < Event
    attr_reader :property, :old_value, :new_value 
    def initialize(node, property, old_value, new_value)
      @property = property
      @old_value = old_value
      @new_value = new_value
      super node
    end
  end
  
  class RelationshipEvent < Event
    attr_reader :to_node, :relation_name, :relation_id
    def initialize(from_node, to_node, relation_name, relation_id)
      @to_node = to_node
      @relation_name = relation_name
      @relation_id = relation_id
      super from_node
    end
    
    def to_s
      super + " relation_name: #{@relation_name} id: #{@relation_id} to_node:#{@to_node}"
    end
  end
  
  class RelationshipAddedEvent < RelationshipEvent
    def initialize(from_node, to_node, relation_name, relation_id)
      super
    end
  end

  class RelationshipDeletedEvent < RelationshipEvent
    def initialize(from_node, to_node, relation_name, relation_id)
      super
    end
  end
  
  class NodeDeletedEvent < Event
    def initialize(node)
      super node
    end
  end
  
  class NodeCreatedEvent < Event
    def initialize(node)
      super node
    end
  end
end
