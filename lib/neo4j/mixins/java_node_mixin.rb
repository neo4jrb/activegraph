module Neo4j::JavaNodeMixin


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
  def rel? (rel_name, dir=:outgoing)
    type = org.neo4j.graphdb.DynamicRelationshipType.withName(rel_name.to_s)
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
  def rels(direction = :outgoing)
    Neo4j::Relationships::RelationshipDSL.new(self, direction)
  end

  # Returns a single relationship or nil if none available.
  # If there are more then one relationship of the given type it will raise an exception.
  #
  # ==== Parameters
  # type<#to_s>:: the key and value to be set
  # dir:: optional, default :outgoing (either, :outgoing, :incoming, :both)
  # raw:: optional, true|false (false default). If false return the ruby wrapped relationship object instead of the raw java neo4j obejct.

  #
  # ==== Returns
  # An object that mixins the Neo4j::RelationshipMixin representing the given relationship type or nil if there are no relationships.
  # If there are more then one relationship it will raise an Exception (java exception of type org.neo4j.graphdb.NotFoundException)
  #
  # ==== See Also
  # * JavaDoc for http://api.neo4j.org/current/org/neo4j/api/core/Node.html#getSingleRelationship(org.neo4j.graphdb.RelationshipType,%20org.neo4j.graphdb.Direction)
  # * Neo4j::RelationshipMixin
  #
  # ==== Example
  #
  #   person_node.rel(:address).end_node[:street]
  #
  def rel(rel_name, dir=:outgoing, raw=false)
    java_dir = _to_java_direction(dir)
    rel_type = org.neo4j.graphdb.DynamicRelationshipType.withName(rel_name.to_s)
    rel = getSingleRelationship(rel_type, java_dir)
    return nil if rel.nil?
    return rel.wrapper unless raw
    rel
  end


  # Adds an outgoing relationship from this node to another node.
  # Will trigger a relationship_created event.
  #
  # ==== Parameters
  # type:: the relationship type between the nodes (respond_to :to_s)
  # to:: the other node (Neo4j::Node || kind_of?(Neo4j::NodeMixin)
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
  def add_rel (type, to, rel_clazz = nil) # :nodoc:
    java_type = org.neo4j.graphdb.DynamicRelationshipType.withName(type.to_s)
    java_rel = createRelationshipTo(to._java_node, java_type)
    # check if we should create a wrapped Ruby Relationship class or use the raw java one.
    rel = (rel_clazz.nil?) ?  java_rel : rel_clazz.new(java_rel)
    Neo4j.event_handler.relationship_created(rel)
    @_wrapper.class.indexer.on_relationship_created(@_wrapper, type) if @_wrapper
    rel
  end

  def _to_java_direction(dir) # :nodoc:
    case dir
      when :outgoing
        org.neo4j.graphdb.Direction::OUTGOING
      when :incoming
        org.neo4j.graphdb.Direction::INCOMING
      when :both
        org.neo4j.graphdb.Direction::BOTH
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
  #   person_node.incoming(:friends).each { ... }
  #   person_node.incoming(:friends).raw(true).each { }
  #
  # The raw false parameter means that the ruby wrapper object will not be loaded, instead the raw Java Neo4j object will be used,
  # it might improve the performance.
  #
  def incoming(*args)
    Neo4j::Relationships::NodeTraverser.new(self).incoming(*args)
  end


  # Deletes this node.
  # Deletes all relationships as well.
  # Invoking any methods on this node after delete() has returned is invalid and may lead to unspecified behavior.
  #
  # :api: public
  def del
    Neo4j.event_handler.node_deleted(wrapper)

    # delete outgoing relationships, and check for cascade delete
    rels.outgoing.each { |r| r.del; r.end_node.del if r[:_cascade_delete_outgoing]}

    rels.incoming.each do |r|
      r.del
      if r[:_cascade_delete_incoming]
        node_id = r[:_cascade_delete_incoming]
        node = Neo4j.load_node(node_id)
        # check node has no outgoing relationships
        no_outgoing = node.rels.outgoing.empty?
        # check node has only incoming relationship with cascade_delete_incoming
        no_incoming = node.rels.incoming.find{|r| !node.ignore_incoming_cascade_delete?(r)}.nil?
        # only cascade delete incoming if no outgoing and no incoming (exception cascade_delete_incoming) relationships
        node.del if no_outgoing and no_incoming
      end
    end
    delete
    @_wrapper.class.indexer.delete_index(self) if @_wrapper
  end

  # --------------------------------------------------------------------------
  # Debug
  #

  # Used for debugging purpose, traverse the graph of given depth and direction and prints nodes and relationship information.
  def print(levels = 0, dir = :outgoing)
    print_sub(0, levels, dir)
  end

  def print_sub(level, max_level, dir) # :nodoc:
    spaces = "  " * level
    node_class = (self[:_classname].nil?) ? Neo4j::Node.to_s : self[:_classname]
    node_desc = "#{spaces}neo_id=#{neo_id} #{node_class}"
    props.each_pair {|key, value| next if %w[id].include?(key) or key.match(/^_/) ; node_desc << " #{key}='#{value}'"}
    puts node_desc

    if (level != max_level)
      rels(dir).each do |rel|
        cascade_desc = ""
        cascade_desc << "cascade in: #{rel[:_cascade_delete_incoming]}" if rel.property?(:_cascade_delete_incoming)
        cascade_desc << "cascade out: #{rel[:_cascade_delete_outgoing]}" if rel.property?(:_cascade_delete_outgoing)
        rel.other_node(self).print_sub(level + 1, max_level, dir)
      end
    end
  end

end
