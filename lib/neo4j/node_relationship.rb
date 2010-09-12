module Neo4j


  module NodeRelationship
    include ToJava

    def outgoing(type=nil)
      if type
        NodeTraverser.new(self).outgoing(type)
      else
        raise "not implemented yet"
        NodeTraverser.new(self)
      end
    end

    def incoming(type=nil)
      if type
        NodeTraverser.new(self).incoming(type)
      else
        raise "not implemented yet"
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


    # Check if the given relationship exists
    # Returns true if there are one or more relationships from this node to other nodes
    # with the given relationship.
    #
    # ==== Parameters
    # type:: the key and value to be set, default any type
    # dir:: optional default :both (either, :outgoing, :incoming, :both)
    #
    # ==== Returns
    # true if one or more relationships exists for the given type and dir
    # otherwise false
    #
    def rel? (type=nil, dir=:both)
      if type
        hasRelationship(type_to_java(type), dir_to_java(dir))
      else
        hasRelationship
      end
    end

  end

end