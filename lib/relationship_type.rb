module Neo
  class RelationshipType
    include org.neo4j.api.core.RelationshipType
    attr_accessor :name 

    @@names = {}
    
    def RelationshipType.instance(name)
      return @@names[name] if @@names.include?(name)
      @@names[name] = RelationshipType.new(name)
    end

    def to_s
      self.class.to_s + " name='#{@name}'"
    end

    private
    
    def initialize(name)
      @name = name.to_s
    end
    
  end
end