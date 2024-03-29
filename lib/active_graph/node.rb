module ActiveGraph
  # Makes Neo4j nodes and relationships behave like ActiveRecord objects.
  # By including this module in your class it will create a mapping for the node to your ruby class
  # by using a Neo4j Label with the same name as the class. When the node is loaded from the database it
  # will check if there is a ruby class for the labels it has.
  # If there Ruby class with the same name as the label then the Neo4j node will be wrapped
  # in a new object of that class.
  #
  # = ClassMethods
  # * {ActiveGraph::Node::Labels::ClassMethods} defines methods like: <tt>index</tt> and <tt>find</tt>
  # * {ActiveGraph::Node::Persistence::ClassMethods} defines methods like: <tt>create</tt> and <tt>create!</tt>
  # * {ActiveGraph::Node::Property::ClassMethods} defines methods like: <tt>property</tt>.
  #
  # @example Create a Ruby wrapper for a Neo4j Node
  #   class Company
  #      include ActiveGraph::Node
  #      property :name
  #   end
  #   company = Company.new
  #   company.name = 'My Company AB'
  #   Company.save
  #
  module Node
    extend ActiveSupport::Concern

    MARSHAL_INSTANCE_VARIABLES = [:@attributes, :@_persisted_obj, :@default_property_value]

    include ActiveGraph::Shared
    include ActiveGraph::Shared::Identity
    include ActiveGraph::Shared::Marshal
    include ActiveGraph::Node::Initialize
    include ActiveGraph::Node::IdProperty
    include ActiveGraph::Shared::SerializedProperties
    include ActiveGraph::Node::Property
    include ActiveGraph::Node::Reflection
    include ActiveGraph::Node::Persistence
    include ActiveGraph::Node::Validations
    include ActiveGraph::Node::Callbacks
    include ActiveGraph::Node::Query
    include ActiveGraph::Node::Labels
    include ActiveGraph::Node::Rels
    include ActiveGraph::Node::Unpersisted
    include ActiveGraph::Node::HasN
    include ActiveGraph::Node::Scope
    include ActiveGraph::Node::Dependent
    include ActiveGraph::Node::Enum
    include ActiveGraph::Shared::PermittedAttributes
    include ActiveGraph::Node::DependentCallbacks
    include ActiveGraph::Transactions

    def initialize(args = nil)
      self.class.ensure_id_property_info! # So that we make sure all objects have an id_property

      args = sanitize_input_parameters(args)
      super(args)
    end

    def neo4j_obj
      _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
    end

    LOADED_CLASSES = []

    def self.loaded_classes
      LOADED_CLASSES
    end

    module ClassMethods
      include ::OrmAdapter::ToAdapter
      def nodeify(object)
        if object.is_a?(::ActiveGraph::Node) || object.nil?
          object
        else
          self.find(object)
        end
      end
    end

    included do
      include ActiveGraph::Timestamps if ActiveGraph::Config[:record_timestamps]
      LOADED_CLASSES << self

      def self.inherited?
        !!@inherited
      end

      def self.inherited(other)
        ActiveGraph::Node::Labels.clear_wrapped_models

        LOADED_CLASSES << other
        other.instance_variable_set('@inherited', true)
        inherit_id_property(other)
        attributes.each_pair do |k, v|
          other.inherit_property k.to_sym, v.clone, declared_properties[k].options
        end

        ActiveGraph::Node::Labels.add_wrapped_class(other)
        super
      end

      def self.inherit_id_property(other)
        return if other.manual_id_property? || !self.id_property?
        id_prop = self.id_property_info
        conf = id_prop[:type].empty? && id_prop[:name] != :neo_id ? {auto: :uuid} : id_prop[:type]
        other.id_property id_prop[:name], conf, true
      end
    end

    ActiveSupport.run_load_hooks(:node, self)
  end
end
