module Neo4j
  module Rails
    # Includes the Neo4j::RelationshipMixin and adds ActiveRecord/Model like behaviour.
    # That means for example that you don't have to care about transactions since they will be
    # automatically be created when needed.
    #
    # By default all relationships created by hte Neo4j::Rails::Model will be of this type unless it is specified by
    # an has_n(...).relationship(relationship_class),
    #
    # Notice that this class works like any ActiveModel compliant object with callbacks and validations.
    # It also implement timestamps (like active record), just add a updated_at or created_at attribute.
    #
    class Relationship
      extend ActiveModel::Translation

      include Neo4j::RelationshipMixin
      include ActiveModel::Dirty # track changes to attributes
      include ActiveModel::Observing # enable observers
      include Neo4j::Rails::Identity
      include Neo4j::Rails::Persistence # handles how to save, create and update the model
      include Neo4j::Rails::RelationshipPersistence # handles how to save, create and update the model
      include Neo4j::Rails::Attributes # handles how to save and retrieve attributes
      include Neo4j::Rails::Serialization # enable to_xml and to_json
      include Neo4j::Rails::Validations # enable validations
      include Neo4j::Rails::Callbacks # enable callbacks
      include Neo4j::Rails::Timestamps # handle created_at, updated_at timestamp properties
      include Neo4j::Rails::Finders # ActiveRecord style find
      include Neo4j::Rails::Compositions

      index :_classname # since there are no rule we have to use lucene to find all instance of a class


      def to_s
        "id: #{self.object_id}  start_node: #{start_node.id} end_node: #{end_node.id} type:#{@type}"
      end

      # --------------------------------------
      # Public Class Methods
      # --------------------------------------
      class << self
        def _all
          _indexer.find(:_classname => self)
        end
      end

    end

  end
end