module Neo4j::JavaRelationshipMixin


  # Check if the given relationship exists
  # Returns true if there are one or more relationships from this node to other nodes
  # with the given relationship.
  # It will not return true only because the relationship is defined.
  #
  # ==== Parameters
  # rel_name<#to_s>:: the key and value to be set
  # dir:: optional default :outgoing (either, :outgoing, :incoming, :both)
  #
  # ==== Returns
  # true if one or more relationships exists for the given rel_name and dir
  # otherwise false
  #
  # :api: public
  def rel? (rel_name, dir=:outgoing)
    type = Neo4j::Relationships::RelationshipType.instance(rel_name.to_s)
    java_dir = _to_java_direction(dir)
    hasRelationship(type, java_dir)
  end


  # Returns a Neo4j::Relationships::RelationshipDSL object for accessing relationships from and to this node.
  # The Neo4j::Relationships::RelationshipDSL is an Enumerable that returns Neo4j::RelationshipMixin objects.
  #
  # ==== Returns
  # A Neo4j::Relationships::RelationshipDSL object
  #
  # ==== See Also
  # * Neo4j::Relationships::RelationshipDSL
  # * Neo4j::RelationshipMixin
  #
  # ==== Example
  #
  #   person_node.rels.outgoing(:friends).each { ... }
  #
  # :api: public
  def rels(direction = :outgoing)
    Neo4j::Relationships::RelationshipDSL.new(self, direction)
  end

  # Returns a single relationship or nil if none available.
  # If there are more then one relationship of the given type it will raise an exception.
  #
  # ==== Parameters
  # type<#to_s>:: the key and value to be set
  # dir:: optional default :outgoing (either, :outgoing, :incoming, :both)
  # raw<true|false (default):: optional, if false return the ruby wrapped relationship object instead of the raw java neo4j obejct.

  #
  # ==== Returns
  # An object that mixins the Neo4j::RelationshipMixin representing the given relationship type or nil if there are no relationships.
  # If there are more then one relationship it will raise an Exception (java exception of type org.neo4j.api.core.NotFoundException)
  #
  # ==== See Also
  # * JavaDoc for http://api.neo4j.org/current/org/neo4j/api/core/Node.html#getSingleRelationship(org.neo4j.api.core.RelationshipType,%20org.neo4j.api.core.Direction)
  # * Neo4j::RelationshipMixin
  #
  # ==== Example
  #
  #   person_node.relationship(:address).end_node[:street]
  #
  # :api: public
  def rel(rel_name, dir=:outgoing, raw=false)
    java_dir = _to_java_direction(dir)
    rel_type = Neo4j::Relationships::RelationshipType.instance(rel_name)
    rel = getSingleRelationship(rel_type, java_dir)
    return nil if rel.nil?
    return rel.wrapper unless raw
    rel
  end


  # Adds an outgoing relationship from this node to another node.
  # Will trigger a relationship_created event.
  #
  # ==== Parameters
  # type<#to_s>:: the relationship type between the nodes
  # to:: the other node
  # raw<true|false (default):: if false return the ruby wrapped relationship object instead of the raw java neo4j obejct.
  #
  # ==== Returns
  # a Neo4j::Relationship object
  #
  # === Example
  # nodeA = Neo4j::Node.new
  # nodeB = Neo4j::Node.new
  # nodeA.add_rel(:friend, nodeB)
  #

  # all creation of relationships uses this method
  # :api: private
  def add_rel (type, to, raw = false) # :nodoc:
    java_type = Neo4j::Relationships::RelationshipType.instance(type)
    to_java_node = to.respond_to?(:_java_node) ? to._java_node : to
    java_rel = createRelationshipTo(to_java_node, java_type)

    # should we wrap the relationship in a ruby object ?
    if (@_wrapper and @_wrapper.class.relationships_info[type.to_sym] and @_wrapper.class.relationships_info[type.to_sym][:relationship])
      rel = @_wrapper.class.relationships_info[type.to_sym][:relationship].new(java_rel)
    else
      rel = java_rel
    end

    Neo4j.event_handler.relationship_created(rel)
    @_wrapper.class.indexer.on_relationship_created(@_wrapper, type) if @_wrapper
    return rel.wrapper unless raw
    rel
  end

  # :api: private
  def _to_java_direction(dir) # :nodoc:
    case dir
      when :outgoing
        org.neo4j.api.core.Direction::OUTGOING
      when :incoming
        org.neo4j.api.core.Direction::INCOMING
      when :both
        org.neo4j.api.core.Direction::BOTH
      else
        raise "Unknown parameter: '#{dir}', only accept :outgoing, :incoming or :both"
    end
  end


  # Returns a Neo4j::Relationships::NodeTraverser object for traversing outgoing nodes from and to this node.
  # The Neo4j::Relationships::NodeTraverser is an Enumerable that returns Neo4j::NodeMixin objects.
  #
  # ==== See Also
  # Neo4j::Relationships::NodeTraverser
  #
  # ==== Example
  #
  #   person_node.outgoing(:friends).each { ... }
  #   person_node.outgoing(:friends).raw(true).each { }
  #
  # The raw false parameter means that the ruby wrapper object will not be loaded, instead the raw Java Neo4j object will be used,
  # it might improve the performance.
  #
  # :api: public
  def outgoing(*args)
    Neo4j::Relationships::NodeTraverser.new(self).outgoing(*args)
  end

  # Returns a Neo4j::Relationships::NodeTraverser object for traversing outgoing nodes from and to this node.
  # The Neo4j::Relationships::NodeTraverser is an Enumerable that returns Neo4j::NodeMixin objects.
  #
  # ==== See Also
  # Neo4j::Relationships::NodeTraverser
  #
  # ==== Example
  #
  #   person_node.outgoing(:friends).each { ... }
  #   person_node.outgoing(:friends).raw(true).each { }
  #
  # The raw false parameter means that the ruby wrapper object will not be loaded, instead the raw Java Neo4j object will be used,
  # it might improve the performance.
  #
  # :api: public
  def incoming(*args)
    Neo4j::Relationships::NodeTraverser.new(self).incoming(*args)
  end

end