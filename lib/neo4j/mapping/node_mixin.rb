module Neo4j::Mapping

  module NodeMixin
    extend Forwardable

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :update, :neo_id, :rels, :rel?, :to_param,
                   :rel, :del, :list?, :list, :lists, :print, :print_sub, :add_rel, :outgoing, :incoming,
                   :add_list_item_methods, :next, :prev, :next=, :prev=, :head,
                   :equal?, :eql?, :==


    # --------------------------------------------------------------------------
    # Initialization methods
    #


    # Creates a new node or loads an already existing Neo4j node.
    #
    # Does
    # * sets the neo4j property '_classname' to self.class.to_s
    # * creates a neo4j node java object (in @_java_node)
    # * calls init_node if that is defined in the current class.
    #
    # If you want to provide your own initialize method you should instead implement the
    # method init_node method.
    #
    # === Example
    #
    #   class MyNode
    #     include Neo4j::NodeMixin
    #
    #     def init_node(name, age)
    #        self[:name] = name
    #        self[:age] = age
    #     end
    #   end
    #
    #   node = MyNode('jimmy', 23)
    #   # notice the following is still possible:
    #   node = MyNode :name => 'jimmy', :age => 12
    #
    # The init_node is only called when the node is created in the database.
    # The initialize method is used both for to purposes:
    # loading an already existing node from the Neo4j database and creating a new node in the database.
    #
    def initialize(*args)
      # was a neo java node provided ?
      if args.length == 1 && args[0].kind_of?(org.neo4j.graphdb.Node)
        # yes, only initialize the ruby wrapper - do not create the node
        init_on_load(args[0])
      else
        # no, a new node should be create

        # init node and set the _classname property
        init_on_create(args[0])

        # has the Ruby wrapper defined an init_node method ?
        init_node(*args) if self.respond_to?(:init_node)
      end

      # was a block given in order to initialize the neo4j node ?
      yield self if block_given?
      # must call super with no arguments so that chaining of the initialize method works
      super()
    end


    # Init this node with the specified java neo node
    #
    def init_on_load(java_node) # :nodoc:
      @_java_node = java_node
    end


    # Creates a new node and initialize with given properties.
    #
    def init_on_create(props) # :nodoc:
      @_java_node = Neo4j::Node.new(props)
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