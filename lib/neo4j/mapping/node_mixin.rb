module Neo4j::Mapping

  module NodeMixin
    extend Forwardable
    include Neo4j::Index

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :attributes, :update, :neo_id, :id, :rels, :rel?, :to_param, :getId,
                   :rel, :del, :list?, :print, :print_sub, :outgoing, :incoming, :both,
                   :equal?, :eql?, :==, :exist?


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
    def init_on_create(*args) # :nodoc:
      self[:_classname] = self.class.to_s
      if args[0].respond_to?(:each_pair)
         args[0].each_pair { |k, v| @_java_node.set_property(k.to_s, v) }
      end
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
        unless c.const_defined?(:DECL_RELATIONSHIPS)
          const_set(:ROOT_CLASS, self)
          const_set(:DECL_RELATIONSHIPS, {})
          const_set(:PROPERTIES_INFO, {})
        end
        class << self
          alias_method :orig_new, :new
        end
      end
      c.extend ClassMethods::Property
      c.extend ClassMethods::Relationship
      c.extend ClassMethods::Aggregate
      c.extend Neo4j::Index::ClassMethods
      def c.inherited(subclass)
        puts "new subclass #{subclass} !!!!!!!"
        subclass.indexer = Neo4j::Index::Indexer.new(subclass)
        super
      end
      c.indexer = Neo4j::Index::Indexer.new(c)

    end


  end
end