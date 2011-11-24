# external third party dependencies
require "active_support/core_ext/module/delegation"

# external neo4j dependencies
require 'neo4j/index/index'
require 'neo4j/property/property'
require 'neo4j/has_n/has_n'
require 'neo4j/rule/rule'
require 'neo4j/has_list/has_list'

# internal dependencies
require 'neo4j/node_mixin/class_methods'


module Neo4j
  # This Mixin is used to wrap Neo4j Java Nodes in Ruby objects.
  #
  # It includes a number of mixins and forwards some methods to the raw Java node (Neo4j::Node) which includes the mixins below:
  #
  # === Instance Methods
  #
  # Mixins:
  # * Neo4j::Index
  # * Neo4j::Property
  # * Neo4j::Rels
  # * Neo4j::Equal
  # * Neo4j::Index
  #
  # === Class Methods
  #
  # Mixins:
  # * Neo4j::NodeMixin::ClassMethods
  # * Neo4j::Property::ClassMethods
  # * Neo4j::HasN::ClassMethods
  # * Neo4j::Rule::ClassMethods
  # * Neo4j::Index::ClassMethods
  # * Neo4j::HasList::ClassMethods
  #
  # This class also includes the class mixin WillPaginate::Finders::Base, see http://github.com/mislav/will_paginate/wiki
  #
  module NodeMixin
    include Neo4j::Index

    include Neo4j::Rule::Functions

    delegate :[]=, :[], :property?, :props, :attributes, :update, :neo_id, :id, :rels, :rel?, :node, :to_param, :getId,
             :rel, :del, :list?, :print, :print_sub, :outgoing, :incoming, :both, :expand, :get_property, :set_property,
             :equal?, :eql?, :==, :exist?, :getRelationships, :getSingleRelationship, :_rels, :rel, :wrapped_entity, :_node,
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
        args[0].each_pair { |k, v| respond_to?("#{k}=") ? self.send("#{k}=", v) : @_java_node[k] = v }
      end
    end

    # Returns the org.neo4j.graphdb.Node wrapped object
    def _java_node
      @_java_node
    end

    # same as _java_node - so that we can use the same method for both relationships and nodes
    def _java_entity
      @_java_node
    end

    # Trigger rules.
    # You don't normally need to call this method (except in Migration) since
    # it will be triggered automatically by the Neo4j::Rule::Rule
    #
    def trigger_rules
      self.class.trigger_rules(self)
    end


    def _decl_rels_for(rel_type)
      self.class._decl_rels[rel_type]
    end

    # Returns self. Implements the same method as the Neo4j::Node#wrapper - duck typing.
    def wrapper
      self
    end


    def self.included(c) # :nodoc:
      c.instance_eval do
        class << self
          alias_method :orig_new, :new
        end
      end unless c.respond_to?(:orig_new)

      c.class_inheritable_accessor :_decl_props
      c._decl_props ||= {}

      c.class_inheritable_accessor :_decl_rels
      c._decl_rels ||= {}

      c.extend ClassMethods
      c.extend Neo4j::Property::ClassMethods
      c.extend Neo4j::HasN::ClassMethods
      c.extend Neo4j::Rule::ClassMethods
      c.extend Neo4j::HasList::ClassMethods
      c.extend Neo4j::Index::ClassMethods
      c.extend WillPaginate::Finders::Base

      def c.inherited(subclass)
        # inherit the index properties
        subclass.node_indexer self

        # inherit the rules too
        subclass.inherit_rules_from self

        super
      end

      c.node_indexer c unless c == Neo4j::Rails::Model
    end
  end
end
