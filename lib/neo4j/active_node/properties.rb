module Neo4j::ActiveNode
  module Properties
    attr_accessor :_properties
    
    def [](key)
      @_properties[key]
    end

    def []=(key,value)
      @_properties[key]=value
    end
  end
end