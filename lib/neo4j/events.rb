# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

module Neo4j
  class Event
    attr_reader :node
    def initialize(node)
      @node = node
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
