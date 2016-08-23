module Neo4j
  # Makes Neo4j nodes and relationships behave like ActiveRecord objects.
  # By including this module in your class it will create a mapping for the node to your ruby class
  # by using a Neo4j Label with the same name as the class. When the node is loaded from the database it
  # will check if there is a ruby class for the labels it has.
  # If there Ruby class with the same name as the label then the Neo4j node will be wrapped
  # in a new object of that class.
  #
  # = ClassMethods
  # * {Neo4j::ActiveNode::Labels::ClassMethods} defines methods like: <tt>index</tt> and <tt>find</tt>
  # * {Neo4j::ActiveNode::Persistence::ClassMethods} defines methods like: <tt>create</tt> and <tt>create!</tt>
  # * {Neo4j::ActiveNode::Property::ClassMethods} defines methods like: <tt>property</tt>.
  #
  # @example Create a Ruby wrapper for a Neo4j Node
  #   class Company
  #      include Neo4j::ActiveNode
  #      property :name
  #   end
  #   company = Company.new
  #   company.name = 'My Company AB'
  #   Company.save
  #
  module ActiveNode
    extend ActiveSupport::Concern

    MARSHAL_INSTANCE_VARIABLES = [:@attributes, :@_persisted_obj, :@default_property_value]

    include Neo4j::Shared
    include Neo4j::Shared::Identity
    include Neo4j::Shared::Marshal
    include Neo4j::ActiveNode::Initialize
    include Neo4j::ActiveNode::IdProperty
    include Neo4j::Shared::SerializedProperties
    include Neo4j::ActiveNode::Property
    include Neo4j::ActiveNode::Reflection
    include Neo4j::ActiveNode::Persistence
    include Neo4j::ActiveNode::Validations
    include Neo4j::ActiveNode::Callbacks
    include Neo4j::ActiveNode::Query
    include Neo4j::ActiveNode::Labels
    include Neo4j::ActiveNode::Rels
    include Neo4j::ActiveNode::Unpersisted
    include Neo4j::ActiveNode::HasN
    include Neo4j::ActiveNode::Scope
    include Neo4j::ActiveNode::Dependent
    include Neo4j::ActiveNode::Enum
    include Neo4j::Shared::PermittedAttributes

    def initialize(args = nil)
      args = sanitize_input_parameters(args)
      super(args)
    end

    def neo4j_obj
      _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
    end

    module ClassMethods
      def nodeify(object)
        if object.is_a?(::Neo4j::ActiveNode) || object.nil?
          object
        else
          self.find(object)
        end
      end
    end

    included do
      include Neo4j::Timestamps if Neo4j::Config[:record_timestamps]

      def self.inherited(other)
        Neo4j::ActiveNode::Labels.clear_wrapped_models

        inherit_id_property(other)
        attributes.each_pair do |k, v|
          other.inherit_property k.to_sym, v.clone, declared_properties[k].options
        end

        Neo4j::ActiveNode::Labels.add_wrapped_class(other)
        super
      end

      def self.inherit_id_property(other)
        Neo4j::Session.on_next_session_available do |_|
          next if other.manual_id_property? || !self.id_property?
          id_prop = self.id_property_info
          conf = id_prop[:type].empty? ? {auto: :uuid} : id_prop[:type]
          other.id_property id_prop[:name], conf
        end
      end

      Neo4j::Session.on_next_session_available do |_|
        next if manual_id_property?
        id_property :uuid, auto: :uuid unless self.id_property?

        name = Neo4j::Config[:id_property]
        type = Neo4j::Config[:id_property_type]
        value = Neo4j::Config[:id_property_type_value]
        id_property(name, type => value) if name && type && value
      end
    end

    ActiveSupport.run_load_hooks(:active_node, self)
  end
end
