module Neo4j


  # 
  # Updates the index. Knows when to update and contains an action
  # proc object to perform the actual update on index.
  #  
  class IndexUpdater
    
    def initialize(clazz, prop_or_rel, prop_or_rel_name, &action)
      @clazz = clazz
      @prop_or_rel = prop_or_rel.to_sym
      @prop_or_rel_name = prop_or_rel_name.to_s
      @action = action
    end
    
    def trigger_on?(event)
      event.match?(@clazz, @prop_or_rel, @prop_or_rel_name)
    end
    
    def index(node)
      @action.call node
    end
  end
end