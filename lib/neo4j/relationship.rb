# external neo4j dependencies
require 'neo4j/property/property'
require 'neo4j/index/index'
require 'neo4j/equal'
require 'neo4j/load'
require 'neo4j/to_java'

module Neo4j


  #
  # A relationship between two nodes in the graph. A relationship has a start node, an end node and a type.
  # You can attach properties to relationships with the API specified in Neo4j::JavaPropertyMixin.
  #
  # Relationship are created by invoking the << operator on the rels method on the node as follow:
  #  node.outgoing(:friends) << other_node << yet_another_node
  #
  # or using the Neo4j::Relationship#new method (which does the same thing):
  #  rel = Neo4j::Relationship.new(:friends, node, other_node)
  #
  # The fact that the relationship API gives meaning to start and end nodes implicitly means that all relationships have a direction.
  # In the example above, rel would be directed from node to otherNode.
  # A relationship's start node and end node and their relation to outgoing and incoming are defined so that the assertions in the following code are true:
  #
  #   a = Neo4j::Node.new
  #   b = Neo4j::Node.new
  #   rel = Neo4j::Relationship.new(:some_type, a, b)
  #   # Now we have: (a) --- REL_TYPE ---> (b)
  #
  #    rel.start_node # => a
  #    rel.end_node   # => b
  #
  # Furthermore, Neo4j guarantees that a relationship is never "hanging freely,"
  # i.e. start_node, end_node and other_node are guaranteed to always return valid, non-null nodes.
  #
  # === Wrapping
  #
  # Notice that the Neo4j::Relationship.new does not create a Ruby object. Instead, it returns a Java 
  # org.neo4j.graphdb.Relationship object which has been modified to feel more rubyish (like Neo4j::Node).
  #
  # === See also
  # * Neo4j::RelationshipMixin if you want to wrap a relationship with your own Ruby class.
  # * http://api.neo4j.org/1.4/org/neo4j/graphdb/Relationship.html
  #
  # === Included Mixins
  # * Neo4j::Property
  # * Neo4j::Equal
  #
  # (Those mixin are actually not included in the Neo4j::Relationship but instead directly included in the java class org.neo4j.kernel.impl.core.RelationshipProxy)
  #
  class Relationship
    extend Neo4j::Index::ClassMethods

    self.rel_indexer self

    class << self
      include Neo4j::Load
      include Neo4j::ToJava


      ##
      # :method: start_node
      #
      # Returns the start node of this relationship


      ##
      # :method: end_node
      #
      # Returns the end node of this relationship

      ##
      # :method: other_node
      #
      # A convenience operation that, given a node that is attached to this relationship, returns the other node. 
      # For example if node is a start node, the end node will be returned, and vice versa.
      # This is a very convenient operation when you're manually traversing the node space by invoking one of the #rels
      # method on a node. For example, to get the node "at the other end" of a relationship, use the following:
      #
      #   end_node = node.rels.first.other_node(node)
      #
      # This operation will throw a runtime exception if node is neither this relationship's start node nor its end node.
      #
      # === Parameters 
      # 
      # node :: the node that we don't want to return
      

      ##
      # :method: del
      #
      # Deletes this relationship. Invoking any methods on this relationship after delete() has returned is invalid and will lead t

      # :method rel_type
      #
      # Returns the type of this relationship.
      # A relationship's type is an immutable attribute that is specified at Relationship creation.
      # The relationship type is othen used when traversing nodes, example finding all the 
      # outgoing nodes of relationship type :friends 
      #  
      #  node.outgoing(:friends)

      # Returns a org.neo4j.graphdb.Relationship java object (!)
      # Will trigger a event that the relationship was created.
      #
      # === Parameters
      # type :: the type of relationship
      # from_node :: the start node of this relationship
      # end_node  :: the end node of this relationship
      # props :: optional properties for the created relationship
      #
      # === Returns
      # org.neo4j.graphdb.Relationship java object
      #
      # === Examples
      #
      #  Neo4j::Relationship.new :friend, node1, node2, :since => '2001-01-02', :status => 'okey'
      #
      def new(type, start_node, end_node, props=nil)
        java_type = type_to_java(type)
        rel = start_node._java_node.create_relationship_to(end_node._java_node, java_type)
        props.each_pair {|k,v| rel[k] = v} if props
        rel
      end

      # create is the same as new
      alias_method :create, :new

      # Loads a relationship or wrapped relationship given a native java relationship or an id.
      # If there is a Ruby wrapper for the node then it will create a Ruby object that will
      # wrap the java node (see Neo4j::RelationshipMixin).
      #
      # If the relationship does not exist it will return nil
      #
      def load(rel_id, db = Neo4j.started_db)
        rel = _load(rel_id, db)
        return nil if rel.nil?
        rel.wrapper
      end

      # Same as load but does not return the node as a wrapped Ruby object.
      #
      def _load(rel_id, db = Neo4j.started_db)
        return nil if rel_id.nil?
        rel = db.graph.get_relationship_by_id(rel_id.to_i)
        rel.hasProperty('_classname')  # since we want a IllegalStateException which is otherwise not triggered
        rel
      rescue java.lang.IllegalStateException
        nil # the node has been deleted
      rescue org.neo4j.graphdb.NotFoundException
        nil
      end

      def extend_java_class(java_clazz)  #:nodoc:
        java_clazz.class_eval do
            include Neo4j::Property
            include Neo4j::Equal

            alias_method :_end_node, :getEndNode
            alias_method :_start_node, :getStartNode
            alias_method :_other_node, :getOtherNode


            # Deletes the relationship between the start and end node
            #
            # May raise an exception if delete was unsuccessful.
            #
            # ==== Returns
            # nil
            #
            def del
              delete
            end

            def end_node # :nodoc:
              getEndNode.wrapper
            end

            def start_node # :nodoc:
              getStartNode.wrapper
            end

            def other_node(node) # :nodoc:
              getOtherNode(node._java_node).wrapper
            end


            # same as _java_rel
            # Used so that we have same method for both relationship and nodes
            def wrapped_entity
              self
            end

            def _java_rel
              self
            end


            # Returns true if the relationship exists
            def exist?
              Neo4j::Relationship.exist?(self)
            end

            # Loads the Ruby wrapper for this node
            # If there is no _classname property for this node then it will simply return itself.
            # Same as Neo4j::Node.load_wrapper(node)
            def wrapper
              self.class.wrapper(self)
            end


            # Returns the relationship name
            #
            # ==== Example
            #   a = Neo4j::Node.new
            #   a.outgoing(:friends) << Neo4j::Node.new
            #   a.rels.first.rel_type # => 'friends'
            #
            def rel_type
              getType().name()
            end

            def class
              Neo4j::Relationship
            end

          end

      end

      Neo4j::Relationship.extend_java_class(org.neo4j.kernel.impl.core.RelationshipProxy)

    end

  end

end


