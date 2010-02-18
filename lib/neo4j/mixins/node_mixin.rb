module Neo4j


  # Represents a node in the Neo4j space.
  # 
  # Is a wrapper around a Java Neo4j::Node (org.neo4j.graphdb.Node)
  # The following methods are delegated to the Java Neo4j::Node
  #   []=, [], property?, props, update, neo_id, rels, rel?, to_param
  #   rel, del, list?, list, lists, print, add_rel, outgoing, incoming,
  #   next, prev, next=, prev=, head
  #
  # Those methods are defined in included mixins
  # This mixin also include the class method in the
  #
  # === Included Mixins
  # * Neo4j::JavaPropertyMixin - instance methods for properties
  # * Neo4j::JavaNodeMixin - instance methods
  # * Neo4j::JavaListMixin - instance methods for list methods
  # * Neo4j::RelClassMethods - class methods for generating relationship accessors
  # * Neo4j::PropertyClassMethods - class methods for generating property accessors
  #
  module NodeMixin
    extend Forwardable

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :update, :neo_id, :rels, :rel?, :to_param,
                   :rel, :del, :list?, :list, :lists, :print, :print_sub, :add_rel, :outgoing, :incoming,
                   :add_list_item_methods, :next, :prev, :next=, :prev=, :head # used for has_list, defined in Neo4j::JavaListMixin


    # --------------------------------------------------------------------------
    # Initialization methods
    #


    # Initialize the the neo node for this instance.
    # Will create a new transaction if one is not already running.
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
    #   # or also possible
    #   node = MyNode :name => 'jimmy', :age => 12
    #
    # The init_node is only called when the node is constructed the first, unlike te initialize method which is used both for
    # loading the node from the Neo4j database and creating the Ruby object.
    #
    def initialize(*args)
      # was a neo java node provided ?
      if args.length == 1 && args[0].kind_of?(org.neo4j.graphdb.Node)
        # yes, it was loaded from the database
        init_with_node(args[0])
      elsif self.respond_to?(:init_node)
        # does the class provide an initialization method ?
        init_without_node({})
        init_node(*args)
      else
        # no, but maybe it had a hash of properties to initialize it with, create node
        init_without_node(args[0] || {})
      end
      # was a block given in order to initialize the neo4j node ?
      yield self if block_given?
      # must call super with no arguments so that chaining of the initialize method works
      super()
    end


    # Inits this node with the specified java neo node
    #
    def init_with_node(java_node) # :nodoc:
      @_java_node = java_node
      java_node._wrapper=self
    end

    # Returns the org.neo4j.graphdb.Node wrapped object
    def _java_node
      @_java_node
    end

    # Creates a new node and initialize with given properties.
    #
    def init_without_node(props) # :nodoc:
      props[:_classname] = self.class.to_s
      @_java_node = Neo4j.create_node props
      @_java_node._wrapper = self
      Neo4j.event_handler.node_created(self)
    end


    # --------------------------------------------------------------------------
    # Property methods
    #


    # Creates a struct class containing all properties of this class.
    # This value object can be used from Ruby on Rails RESTful routing.
    #
    # ==== Example
    #
    # h = Person.value_object.new
    # h.name    # => nil
    # h.name='kalle'
    # h[:name]   # => 'kalle'
    #
    # ==== Returns
    # a value object struct
    #
    def value_object
      vo = self.class.value_object.new
      vo._update(props)
      vo
    end


    # --------------------------------------------------------------------------
    # Equal and hash methods
    #

    def equal?(o)
      eql?(o)
    end

    def eql?(o)
      o.kind_of?(NodeMixin) && o._java_node == @_java_node
    end

    def ==(o)
      eql?(o)
    end

    def hash
      @_java_node.hashCode
    end


    # --------------------------------------------------------------------------
    # Update and Delete methods
    #


    # Specifies which relationships should be ignored when trying to cascade delete a node.
    # If a node does not have any relationships (except those specified here to ignore) it will be cascade deleted
    #
    def ignore_incoming_cascade_delete?(relationship) # :nodoc:
      # ignore relationship with property _cascade_delete_incoming
      relationship.property?(:_cascade_delete_incoming)
    end

    # Updates the index for this node.
    # This method will be automatically called when needed
    # (a property changed or a relationship was created/deleted)
    #
    def update_index # :nodoc:
      self.class.indexer.index(self)
    end

    # --------------------------------------------------------------------------
    # Relationship methods
    #

    # Returns a Neo4j::Relationships::NodeTraverser object for traversing nodes from and to this node.
    # The Neo4j::Relationships::NodeTraverser is an Enumerable that returns Neo4j::NodeMixin objects.
    #
    # ==== Example
    #
    #   person_node.traverse.outgoing(:friends).each { ... }
    #   person_node.traverse.outgoing(:friends).raw.each { }
    #
    # The raw false parameter means that the ruby wrapper object will not be loaded, instead the raw Java Neo4j object will be used,
    # it might improve the performance.
    #
    def traverse(*args)
      if args.empty?
        Neo4j::Relationships::NodeTraverser.new(self)
      else
        @_java_node.traverse(*args)
      end

    end


    # --------------------------------------------------------------------------
    # Private methods
    #

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


    # --------------------------------------------------------------------------
    # Hooks
    #


    # Adds class methods from
    #
    # * Neo4j::RelClassMethods
    # * Neo4j::PropertyClassMethods
    #
    def self.included(c) # :nodoc:
      c.instance_eval do
        # these constants are used in the Neo4j::RelClassMethods and Neo4j::PropertyClassMethods
        # they are defined here since they should only be defined once -
        # all subclasses share the same index, declared properties and index_updaters
        const_set(:ROOT_CLASS, self)
        const_set(:DECL_RELATIONSHIPS, {})
        const_set(:PROPERTIES_INFO, {})
      end unless c.const_defined?(:DECL_RELATIONSHIPS)

      c.extend Neo4j::RelClassMethods
      c.extend Neo4j::PropertyClassMethods
    end
  end
end
