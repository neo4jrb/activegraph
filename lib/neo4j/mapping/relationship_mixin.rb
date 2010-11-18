module Neo4j::Mapping

  module RelationshipMixin
    extend Forwardable
    include Neo4j::Index

    def_delegators :@_java_rel, :[]=, :[], :property?, :props, :attributes, :update, :neo_id, :id, :to_param, :getId,
                   :equal?, :eql?, :==, :delete, :getStartNode, :getEndNode, :getOtherNode, :exist?



    # --------------------------------------------------------------------------
    # Initialization methods
    #


    # Init this node with the specified java neo4j relationship.
    #
    def init_on_load(java_rel) # :nodoc:
      @_java_rel = java_rel
    end


    # Creates a new node and initialize with given properties.
    #
    def init_on_create(*args) # :nodoc:
      type, from_node, to_node, props = args
      self[:_classname] = self.class.to_s
      if props.respond_to?(:each_pair)
        props.each_pair { |k, v| @_java_rel.set_property(k.to_s, v) }
      end
    end


    # --------------------------------------------------------------------------
    # Instance Methods
    #

    # Returns the org.neo4j.graphdb.Relationship wrapped object
    def _java_rel
      @_java_rel
    end

    # Returns the end node of this relationship
    def end_node
      id = getEndNode.getId
      Neo4j::Node.load(id)
    end

    # Returns the start node of this relationship
    def start_node
      id = getStartNode.getId
      Neo4j::Node.load(id)
    end

    # Deletes this relationship
    def del
      delete
    end

    def exist?
      Neo4j::Relationship.exist?(self)
    end

    # A convenience operation that, given a node that is attached to this relationship, returns the other node.
    # For example if node is a start node, the end node will be returned, and vice versa.
    # This is a very convenient operation when you're manually traversing the node space by invoking one of the #rels operations on node.
    #
    # This operation will throw a runtime exception if node is neither this relationship's start node nor its end node.
    #
    # ==== Example
    # For example, to get the node "at the other end" of a relationship, use the following:
    #   Node endNode = node.rel(:some_rel_type).other_node(node)
    #
    def other_node(node)
      neo_node = node.respond_to?(:_java_node)? node._java_node : node
      id = getOtherNode(neo_node).getId
      Neo4j::Node.load(id)
    end


    # Returns the neo relationship type that this relationship is used in.
    # (see java API org.neo4j.graphdb.Relationship#getType  and org.neo4j.graphdb.RelationshipType)
    #
    # ==== Returns
    # the relationship type (of type Symbol)
    #
    def relationship_type
      get_type.name.to_sym
    end

    # --------------------------------------------------------------------------
    # Class Methods
    #

    class << self
      def included(c) # :nodoc:
        c.instance_eval do
          class << self
            alias_method :orig_new, :new
          end
        end
        
        c.class_inheritable_hash :_decl_props
        c._decl_props ||= {}
        
        c.extend ClassMethods::Root
        c.extend ClassMethods::Property
        c.extend ClassMethods::InitRel
        c.extend Neo4j::Index::ClassMethods

        def c.inherited(subclass)
          subclass.rel_indexer subclass
          super
        end

        c.rel_indexer c
      end
    end
  end
end