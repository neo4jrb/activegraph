require "active_support/core_ext/module/delegation"

module Neo4j::Mapping

  # This Mixin is used to wrap Neo4j Java Nodes in Ruby objects.
  #
  # It includes a number of mixins and forwards some methods to the raw Java node which in term includes a number of mixins, see below.
  #
  # === Instance Methods
  #
  # Mixins:
  # * Neo4j::Index
  # * Neo4j::Property
  # * Neo4j::NodeRelationship
  # * Neo4j::Equal
  # * Neo4j::Index
  #
  # === Class Methods
  #
  # Mixins:
  # * Neo4j::Mapping::ClassMethods::Root
  # * Neo4j::Mapping::ClassMethods::Property
  # * Neo4j::Mapping::ClassMethods::InitNode
  # * Neo4j::Mapping::ClassMethods::Relationship
  # * Neo4j::Mapping::ClassMethods::Rule
  # * Neo4j::Mapping::ClassMethods::List
  # * Neo4j::Index::ClassMethods
  #
  module NodeMixin
    include Neo4j::Index

    include Neo4j::Functions

    delegate :[]=, :[], :property?, :props, :attributes, :update, :neo_id, :id, :rels, :rel?, :to_param, :getId,
             :rel, :del, :list?, :print, :print_sub, :outgoing, :incoming, :both, :expand, :get_property, :set_property,
             :equal?, :eql?, :==, :exist?, :getRelationships, :getSingleRelationship, :_rels, :rel, 
             :to => :@_java_node, :allow_nil => true 


    # --------------------------------------------------------------------------
    # Initialization methods
    #


    # Init this node with the specified java neo node
    #
    def init_on_load(java_node) # :nodoc:
      @_java_node = java_node
    end


    # Creates a new node and initialize with given properties.
    # You can override this to provide your own initialization.
    #
    def init_on_create(*args) # :nodoc:
      self[:_classname] = self.class.to_s
      if args[0].respond_to?(:each_pair)
        args[0].each_pair { |k, v| respond_to?("#{k}=")? self.send("#{k}=", v) : @_java_node[k] = v }
      end
    end

    # Returns the org.neo4j.graphdb.Node wrapped object
    def _java_node
      @_java_node
    end

    def trigger_rules
      self.class.trigger_rules(self)
    end


    def _decl_rels_for(rel_type)
      self.class._decl_rels[rel_type]
    end
    
    def wrapper
      self
    end


    def self.included(c) # :nodoc:
      c.instance_eval do
        class << self
          alias_method :orig_new, :new
        end
      end unless c.respond_to?(:orig_new)

      c.class_inheritable_hash :_decl_props
      c._decl_props ||= {}

      c.class_inheritable_hash :_decl_rels
      c._decl_rels ||= {}

      c.extend ClassMethods::Property
      c.extend ClassMethods::InitNode
      c.extend ClassMethods::Relationship
      c.extend ClassMethods::Rule
      c.extend ClassMethods::List
      c.extend Neo4j::Index::ClassMethods
      c.extend WillPaginate::Finders::Base

      def c.inherited(subclass)
        # inherit the index properties
        subclass.node_indexer self

        # inherit the rules too
        subclass.inherit_rules_from self

        super
      end

      c.node_indexer c
    end
  end
end