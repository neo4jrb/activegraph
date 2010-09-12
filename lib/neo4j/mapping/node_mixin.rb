module Neo4j::Mapping

  module NodeMixin
    extend Forwardable

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :attributes, :update, :neo_id, :id, :rels, :rel?, :to_param, :getId,
                   :rel, :del, :list?, :print, :print_sub, :outgoing, :incoming, :both,
                   :equal?, :eql?, :==


    # --------------------------------------------------------------------------
    # Initialization methods
    #


    # Init this node with the specified java neo node
    #
    def init_on_load(java_node) # :nodoc:
      @_java_node = java_node
    end


    # Creates a new node and initialize with given properties.
    #
    def init_on_create(*) # :nodoc:
      self[:_classname] = self.class.to_s
    end

    # Returns the org.neo4j.graphdb.Node wrapped object
    def _java_node
      @_java_node
    end

    def id
      @_java_node.id
    end

    def self.included(c) # :nodoc:
      c.instance_eval do
        # these constants are used in the Neo4j::RelClassMethods and Neo4j::PropertyClassMethods
        # they are defined here since they should only be defined once -
        # all subclasses share the same index, declared properties and index_updaters
        const_set(:ROOT_CLASS, self)
        const_set(:DECL_RELATIONSHIPS, {})
        const_set(:PROPERTIES_INFO, {})
      end unless c.const_defined?(:DECL_RELATIONSHIPS)

      c.extend Neo4j::Mapping::PropertyClassMethods
      c.extend Neo4j::Mapping::IndexClassMethods
      c.extend Neo4j::Mapping::RelationshipClassMethods
    end

  end
end