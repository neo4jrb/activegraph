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

    include Neo4j::Shared
    include Neo4j::Shared::Identity
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
    include Neo4j::ActiveNode::HasN
    include Neo4j::ActiveNode::Scope

    def neo4j_obj
      _persisted_obj || raise("Tried to access native neo4j object on a non persisted object")
    end

    included do
      def self.inherited(other)
        inherit_id_property(other) if self.has_id_property?
        inherited_indexes(other) if self.respond_to?(:indexed_properties)
        attributes.each_pair { |k,v| other.attributes[k] = v }
        inherit_serialized_properties(other) if self.respond_to?(:serialized_properties)
        Neo4j::ActiveNode::Labels.add_wrapped_class(other)
        super
      end

      def self.inherited_indexes(other)
       return if indexed_properties.nil?
       self.indexed_properties.each { |property| other.index property }
      end

      def self.inherit_serialized_properties(other)
        other.serialized_properties = self.serialized_properties
      end

      def self.inherit_id_property(other)
        id_prop = self.id_property_info
        conf = id_prop[:type].empty? ? { auto: :uuid } : id_prop[:type]
        other.id_property id_prop[:name], conf
      end

      Neo4j::Session.on_session_available do |_|
        id_property :uuid, auto: :uuid unless self.has_id_property?

        name = Neo4j::Config[:id_property]
        type = Neo4j::Config[:id_property_type]
        value = Neo4j::Config[:id_property_type_value]
        id_property(name, type => value) if (name && type && value)
      end
    end

    ActiveSupport.run_load_hooks(:active_node, self)
  end
end
