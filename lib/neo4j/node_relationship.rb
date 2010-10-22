module Neo4j


  module NodeRelationship
    include ToJava


    # Returns the outgoing nodes for this node.
    #
    # ==== Returns
    # a Neo4j::NodeTraverser which can be used to further specify which nodes should be included
    # in traversal by using the <tt>depth</tt>, <tt>filter</tt> and <tt>prune</tt> methods.
    #
    # ==== Examples
    #   # Find all my friends (nodes of depth 1 of type <tt>friends</tt>)
    #   me.outgoing(:friends).each {|friend| puts friend[:name]}
    #
    #   # Find all my friends and their friends (nodes of depth 1 of type <tt>friends</tt>)
    #   # me.outgoing(:friends).depth(2).each {|friend| puts friend[:name]}
    #
    #   # Find all my friends and include my self in the result
    #   me.outgoing(:friends).depth(4).include_start_node.each {...}
    #
    #   # Find all my friends friends friends, etc. at any depth
    #   me.outgoing(:friends).depth(:all).each {...}
    #
    #   # Find all my friends friends but do not include my friends (only depth == 2)
    #   me.outgoing(:friends).depth(2).filter{|path| path.length == 2}
    #
    #   # Find all my friends but 'cut off' some parts of the traversal path
    #   me.outgoing(:friends).depth(42).prune(|path| an_expression_using_path_returning_true_false }
    #
    #   # Find all my friends and work colleges
    #   me.outgoing(:friends).outgoing(:work).each {...}
    #
    # Of course all the methods <tt>outgoing</tt>, <tt>incoming</tt>, <tt>both</tt>, <tt>depth</tt>, <tt>include_start_node</tt>, <tt>filter</tt>, and <tt>prune</tt> can be combined.
    #
    def outgoing(type)
      if type
        NodeTraverser.new(self).outgoing(type)
      else
        raise "not implemented yet"
        NodeTraverser.new(self)
      end
    end


    # Returns the incoming nodes of given type(s).
    #
    # See #outgoing
    #
    def incoming(type)
      if type
        NodeTraverser.new(self).incoming(type)
      else
        raise "not implemented yet"
        NodeTraverser.new(self)
      end
    end

    # Returns both incoming and outgoing nodes of given types(s)
    #
    # If a type is not given then it will return all types of relationships.
    #
    # See #outgoing
    #
    def both(type=nil)
      if type
        NodeTraverser.new(self).both(type)
      else
        NodeTraverser.new(self) # default is both
      end
    end


    # Returns an enumeration of relationship objects.
    # It always returns relationship of depth one.
    #
    # See Neo4j::Relationship
    #
    # ==== Examples
    #   # Return both incoming and outgoing relationships
    #   me.rels(:friends, :work).each {|relationship|...}
    #
    #   # Only return outgoing relationship of given type
    #   me.rels(:friends).outgoing.first.end_node # => my friend node
    #
    def rels(*type)
      RelationshipTraverser.new(self, type, :both)
    end


    # Returns the only relationship of a given type and direction that is attached to this node, or null.
    # This is a convenience method that is used in the commonly occuring situation where a node has exactly zero or
    # one relationships of a given type and direction to another node.
    # Typically this invariant is maintained by the rest of the code: if at any time more than one such relationships
    # exist, it is a fatal error that should generate an unchecked exception. This method reflects that semantics and
    # returns either:
    #
    # * nil if there are zero relationships of the given type and direction,
    # * the relationship if there's exactly one, or
    # * raise an exception in all other cases.
    def rel(dir, type)
      result = _rel(dir, type)
      result && result.wrapper
    end

    # Same as rel but does not return a ruby wrapped object but instead returns the Java object.
    def _rel(dir, type)
      get_single_relationship(type_to_java(type), dir_to_java(dir))
    end

    # Returns the raw java neo4j relationship object.
    def rels_raw(dir=:both, *types)
      if types.size > 1
        java_types = types.inject([]) { |result, type| result << type_to_java(type) }.to_java(:'org.neo4j.graphdb.RelationshipType')
        get_relationships(java_types)
      elsif types.size == 1
        get_relationships(type_to_java(types[0], dir_to_java(dir)))
      elsif dir == :both
        get_relationships(dir_to_java(dir))
      else
        raise "illegal argument, does not accept #{dir} #{types.join(',')} - only dir=:both for any relationship types"
      end
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
