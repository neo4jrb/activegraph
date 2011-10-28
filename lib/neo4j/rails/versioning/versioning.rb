module Neo4j
  module Rails
    # Adds snapshot based versioning to Neo4j Rails models
    # To use versioning, include this module in your model.
    #
    # Example:
    #   class VersionableModel < Neo4j::Rails::Model
    #     include Neo4j::Rails::Versioning
    #   end
    #
    # To find out the number of versions of an instance, you can use the current_version method.
    #
    # To retrieve a snapshot of an older version, use the version method.
    #   snapshot = instance.version(1) #Retrieves version 1.
    #
    # Note that the version numbers start from 1 onwards.
    #
    # The snapshot retains all the properties and relationships at the point when a versioned model is saved.
    # The snapshot also allows you to traverse incoming and outgoing relationships.
    #
    # For example:
    #   snapshot.incoming(:friends) would return a collection of nodes that are related via the friends relationship.
    #
    # The snapshot node creates relationships with a model's related nodes with a "version_" prefix in order to
    # avoid name clashes. However, you can call the incoming and outgoing methods using your model's relationship names.
    #
    # To control the maximum number of versions created, you can use the max_versions property.
    #
    # Example:
    #   class MaxVersionableModel < Neo4j::Rails::Model
    #     include Neo4j::Rails::Versioning
    #     max_versions 10
    #   end
    module Versioning
      extend ActiveSupport::Concern

      class Version
        include Neo4j::RelationshipMixin
        property :number, :type => Fixnum
        property :instance_id, :type => Fixnum
        property :model_classname
        index :number, :instance_id, :model_classname
      end

      class Snapshot
        include Neo4j::NodeMixin

        def incoming(rel_type)
          super "version_#{rel_type.to_s}".to_sym
        end

        def outgoing(rel_type)
          super "version_#{rel_type.to_s}".to_sym
        end
      end

      included do
        class_attribute :version_max
        property :_version, :type => Fixnum
      end

      ##
      # Returns the current version of a model instance
      def current_version
        self._version ||= 0
      end

      ##
      # Returns the snapshot version for a given instance.
      # @param [ Integer ] number The version number to retrieve.
      # Returns nil in case a version is not found.
      def version(number)
        Version.find(:model_classname => _classname, :instance_id => neo_id, :number => number) {|query| query.first.nil? ? nil : query.first.end_node}
      end

      ##
      # Overrides Rails's save method to save snapshots.
      def save
        if self.changed? || self.relationships_changed?
          self._version = current_version + 1
          super
          revise
        end
      end

      private
      def revise
        Neo4j::Transaction.run do
          snapshot = Snapshot.new(self.props.reject{|key, value| key.to_sym == :_classname})
          version_relationships(snapshot)
          delete_old_version if version_max.present? && number_of_versions >= version_max
          Version.new(:version, self, snapshot, :model_classname => _classname, :instance_id => neo_id, :number => current_version)
        end
      end

      def number_of_versions
        Version.find(:model_classname => _classname, :instance_id => neo_id) {|query| query.size}
      end

      def version_relationships(snapshot)
        self._java_node.getRelationships().each do |rel|
          if (self._java_node == rel.getStartNode())
            snapshot._java_node.createRelationshipTo(rel.getEndNode(), relationship_type(rel.getType()))
          else
            rel.getStartNode().createRelationshipTo(snapshot._java_node, relationship_type(rel.getType()))
          end
        end
      end

      def relationship_type(rel_type)
        org.neo4j.graphdb.DynamicRelationshipType.withName( "version_#{rel_type.name}" )
      end

      def delete_old_version
        versions = Version.find(:model_classname => _classname).asc(:number)
        versions.first.del
        versions.close
      end

      module ClassMethods #:nodoc:

        # Sets the maximum number of versions to store.
        #
        # @param [ Integer ] number The maximum number of versions to store.
        def max_versions(number)
          self.version_max = number.to_i
        end
      end
    end
  end
end