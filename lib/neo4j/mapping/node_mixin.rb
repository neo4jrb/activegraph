module Neo4j::Mapping

  module NodeMixin
    extend Forwardable
    include Neo4j::Index

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :attributes, :update, :neo_id, :id, :rels, :rel?, :to_param, :getId,
                   :rel, :del, :list?, :print, :print_sub, :outgoing, :incoming, :both,
                   :equal?, :eql?, :==, :exist?, :getRelationships, :getSingleRelationship, :rels_raw


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

    def trigger_rules
      self.class.trigger_rules(self)
    end


    def wrapper
      self
    end

    def self.included(c) # :nodoc:
      c.instance_eval do
        class << self
          alias_method :orig_new, :new
        end
      end

      c.extend ClassMethods::Root
      c.extend ClassMethods::Property
      c.extend ClassMethods::InitNode
      c.extend ClassMethods::Relationship
      c.extend ClassMethods::Rule
      c.extend Neo4j::Index::ClassMethods

      def c.inherited(subclass)
        subclass.node_indexer subclass
        subclass.root_class subclass
        super
      end

      c.node_indexer c
      c.root_class c
    end
  end
end