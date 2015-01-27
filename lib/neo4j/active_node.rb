module Neo4j
  # Adds ActiveRecord-like methods to Ruby classes to easily work with Neo4j objects. Where possible,
  # it follows ActiveRecord's behavior to make things easy and predictable.
  #
  # Like classes inheriting from ActiveRecord::Base, classes including Neo4j::ActiveNode are able to create,
  # return, update, and destroy Neo4j nodes using provided methods. Node models can also define associations to
  # other models and use callbacks and validations.
  #
  # Class names are directly mapped to label names with Neo4j: a `Student` class will create Student nodes.
  # When a node is returned from the database, the label(s) is/are used to to determine what model to load.
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
    include Neo4j::ActiveNode::Dependent

    # Every wrapped node and relationship has an underlying unwrapped CypherNode/CypherRelationship or EmbeddedNode/EmbeddedRelationship object.
    # This method provides access to that.
    # The unwrapped object is useful for performing actions that aren't easy or possible with Active*-wrapped objects, like
    # accessing undeclared properties.
    # @return [Neo4j::Server::CypherNode, Neo4j::Embedded::EmbeddedNode]
    def neo4j_obj
      _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
    end

    private

    included do
      def self.inherited(other)
        super(other)
        attributes.each_pair { |k, v| other.attributes[k] = v }
      end

      Neo4j::Session.on_session_available do |_|
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
