module Neo4j
  
  class RelationInfo
    attr_accessor :info 
    def initialize
      @info = {}
      @info[:relation] = DynamicRelation
    end
    
    
    def [](key)
      @info[key]
    end
    
    def to(clazz)
      @info[:outgoing] = true
      @info[:class] = clazz
      self
    end
    
    def from(clazz, type)
      @info[:outgoing] = false
      @info[:class] = clazz
      @info[:type] = type
      self
    end
    
    
    def relation(rel_class)
      @info[:relation_class] = rel_class
      self
    end
  end
  
end