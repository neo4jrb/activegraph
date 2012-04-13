module Neo4j
  # Includes the Neo4j::NodeMixin and adds ActiveRecord/Model like behaviour.
  # That means for example that you don't have to care about transactions since they will be
  # automatically be created when needed.
  #
  # ==== Included Mixins
  #
  # * Neo4j::Rails::Persistence :: handles how to save, create and update the model
  # * Neo4j::Rails::Attributes :: handles how to save and retrieve attributes
  # * Neo4j::Rails::Mapping::Property :: allows some additional options on the #property class method
  # * Neo4j::Rails::Serialization :: enable to_xml and to_json
  # * Neo4j::Rails::Timestamps :: handle created_at, updated_at timestamp properties
  # * Neo4j::Rails::Validations :: enable validations
  # * Neo4j::Rails::Callbacks :: enable callbacks
  # * Neo4j::Rails::Finders :: ActiveRecord style find
  # * Neo4j::Rails::Relationships :: handles persisted and none persisted relationships.
  # * Neo4j::Rails::Compositions :: see Neo4j::Rails::Compositions::ClassMethods, similar to http://api.rubyonrails.org/classes/ActiveRecord/Aggregations/ClassMethods.html
  # * ActiveModel::Observing # enable observers, see Rails documentation.
  # * ActiveModel::Translation - class mixin
  #
  # ==== Traversals
  # This class only expose a limited set of traversals.
  # If you want to access the raw java node to do traversals use the _java_node.
  #
  #   class Person < Neo4j::RailsNode
  #   end
  #
  #   person = Person.find(...)
  #   person._java_node.outgoing(:foo).depth(:all)...
  #
  # ==== has_n and has_one
  #
  # The has_n and has_one relationship accessors returns objects of type Neo4j::Rails::Relationships::RelsDSL
  # and Neo4j::Rails::Relationships::NodesDSL which behaves more like the Active Record relationships.
  # Notice that unlike Neo4j::NodeMixin new relationships are kept in memory until @save@ is called.
  #
  # ==== Callbacks
  #
  # The following callbacks are supported :initialize, :validation, :create, :destroy, :save, :update.
  # It works with before, after and around callbacks, see the Rails documentation.
  # Notice you can also do callbacks using the Neo4j::Rails::Callbacks module (check the Rails documentation)
  #
  # ==== Examples
  #
  #   person.outgoing(:friends) << other_person
  #   person.save!
  #
  #   person.outgoing(:friends).map{|f| f.outgoing(:knows).to_a}.flatten
  #
  # ==== Examples
  #
  #   Neo4j::Transaction.run do
  #     person._java_node.outgoing(:friends) << other_person
  #   end
  #
  #   person._java_node.outgoing(:friends).outgoing(:knows).depth(4)
  #
  # Notice you can also declare outgoing relationships with the #has_n and #has_one class method.
  #
  # See Neo4j::RailsRelationships#outgoing
  # See Neo4j::Traversal#outgoing (when using it from the _java_node)
  class RailsNode
    extend ActiveModel::Translation

    include Neo4j::NodeMixin
    include ActiveModel::Dirty # track changes to attributes
    include ActiveModel::MassAssignmentSecurity # handle attribute hash assignment
    include ActiveModel::Observing # enable observers
    include Neo4j::Rails::Identity
    include Neo4j::Rails::Persistence # handles how to save, create and update the model
    include Neo4j::Rails::NodePersistence # handles how to save, create and update the model
    include Neo4j::Rails::Attributes # handles how to save and retrieve attributes and override the property class method
    include Neo4j::Rails::NestedAttributes
    include Neo4j::Rails::HasN # allows some additional options on the #property class method
    include Neo4j::Rails::Serialization # enable to_xml and to_json
    include Neo4j::Rails::Validations # enable validations
    include Neo4j::Rails::Callbacks # enable callbacks
    include Neo4j::Rails::Timestamps # handle created_at, updated_at timestamp properties
    include Neo4j::Rails::Finders # ActiveRecord style find
    include Neo4j::Rails::Relationships # for none persisted relationships
    include Neo4j::Rails::Compositions
    include Neo4j::Rails::AcceptId
    include Neo4j::Rails::Relationships

                               # --------------------------------------
    # Public Class Methods
    # --------------------------------------
    class << self

      ##
      # Determines whether to use Time.local (using :local) or Time.utc (using :utc) when pulling
      # dates and times from the database. This is set to :local by default.
      # @api public
      def default_timezone
        @default_timezone || :local
      end

      # @api public
      def default_timezone=(zone)
        @default_timezone = zone
      end

      # Set the i18n scope to overwrite ActiveModel.
      #
      # @return [ Symbol ] :neo4j
      # @api public
      def i18n_scope
        :neo4j
      end
    end
  end
end
