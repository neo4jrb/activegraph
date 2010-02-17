module Neo4j


  # A module that can be mixed in like a Neo4j::NodeMixin
  # It wraps the Neo4j Relationship class.
  # It includes the Neo4j::PropertyClassMethods class methods.
  #
  module RelationshipMixin
    extend Forwardable

    attr_reader :_java_node

    def_delegators :@_java_node, :[]=, :[], :property?, :props, :update, :neo_id, :del, :start_node, :end_node, :other_node, :relationship_type, :wrapper

    # Initialize the Relationship object with specified java org.neo4j.graphdb.Relationship object
    # Expects at least one parameter.
    #
    # This method is used both when neo4j.rb loads relationships from the database as well as when
    # a relationship is first created.
    #
    # Method init_with_args are called if first argument is not kind of Java::org.neo4j.graphdb.Relationship
    #
    # ==== Parameters (loading from DB)
    # param1<org.neo4j.graphdb.Relationship>:: the internal java relationship object
    #
    # ==== Parameters (creating new relationship
    # type:: the key and value to be set
    # from_node:: create relationship from this node
    # to:: create relationship to this node
    #
    def initialize(*args)
      if (args[0].kind_of?(Java::org.neo4j.graphdb.Relationship))
        init_with_rel(args[0])
      else
        init_with_args(*args)
      end

      # must call super with no arguments so that chaining of initialize method will work
      super()
    end


    # Initialize this relationship with the given arguments

    # ==== Parameters
    # type:: the key and value to be set
    # from_node:: create relationship from this node
    # to_node:: create relationship to this node
    def init_with_args(type, from_node, to_node)
      @_java_node = Neo4j.create_rel(type, from_node, to_node)
      @_java_node._wrapper = self
      @_java_node[:_classname] = self.class.to_s
      Neo4j.event_handler.relationship_created(self)
      self.class.indexer.on_relationship_created(@_wrapper, type) 
    end

    # Inits this node with the specified java neo relationship
    #
    # :api: private
    def init_with_rel(rel)
      @_java_node = rel # TODO hmm, should really name _java_node to something else
      rel._wrapper=self
      rel[:_classname] = self.class.to_s unless rel.property?(:_classname)
    end


    def eql?(o)
      o.kind_of?(RelationshipMixin) && o.internal_r == internal_r
    end

    def ==(o)
      eql?(o)
    end

    def hash
      _java_node.hashCode
    end

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
        const_set(:PROPERTIES_INFO, {})
      end unless c.const_defined?(:ROOT_CLASS)
      c.extend Neo4j::PropertyClassMethods
      c.extend ClassMethods
    end

    module ClassMethods
      def indexer # :nodoc:
        Neo4j::Indexer.instance(root_class, false) # create an indexer that search for relationships (and not nodes)
      end
    end
  end
end
