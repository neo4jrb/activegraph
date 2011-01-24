require 'neo4j/rels/traverser'


module Neo4j

  # Contains methods for traversing relationship object of depth one from one node.
  module Rels
    include ToJava

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
      Traverser.new(self, type, :both)
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
    def _rels(dir=:both, *types)
      if types.size > 1
        java_types = types.inject([]) { |result, type| result << type_to_java(type) }.to_java(:'org.neo4j.graphdb.RelationshipType')
        get_relationships(java_types)
      elsif types.size == 1
        get_relationships(type_to_java(types[0]), dir_to_java(dir))
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


