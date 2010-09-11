module Neo4j


  module NodeRelationship
    def outgoing(type=nil)
      if type
        NodeTraverser.new(self).outgoing(type)
      else
        NodeTraverser.new(self)
      end
    end

    def incoming(type=nil)
      if type
        NodeTraverser.new(self).incoming(type)
      else
        NodeTraverser.new(self)
      end
    end

    def both(type=nil)
      if type
        NodeTraverser.new(self).both(type)
      else
        NodeTraverser.new(self) # default is both
      end
    end

    def rels(*type)
      RelationshipTraverser.new(self, type, :both)
    end

  end

end