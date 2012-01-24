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

        def assign(key,value)
          @converted_properties = {} if @converted_properties.nil?
          @converted_properties[key.to_sym] = value
        end

        def [](key)
          return @converted_properties[key] if @converted_properties
          super(key)
        end

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
        snapshot = Version.find(:model_classname => _classname, :instance_id => neo_id, :number => number) {|query| query.first.nil? ? nil : query.first.end_node}
        snapshot.props.each_pair{|k,v| snapshot.assign(k,Neo4j::TypeConverters.to_ruby(self.class, k, v))} if !snapshot.nil?
        snapshot
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

      ##
      # Reverts this instance to a specified version
      # @param [ Integer ] version_number The version number to revert to.
      # Reverting the instance will increment the current version number.
      def revert_to(version_number)
        snapshot = version(version_number)
        self.props.each_pair{|k,v| self[k] = nil if !snapshot.props.has_key?(k)}
        snapshot.props.each_pair{|k,v| self[k] = v if self.props[k].nil? && k != '_neo_id'}
        Neo4j::Transaction.run do
          restore_relationships(snapshot)
          save
        end
      end

      private
      def revise
        Neo4j::Transaction.run do
          snapshot = Snapshot.new(converted_properties)
          each_versionable_relationship{|rel| create_version_relationship(rel,snapshot)}
          delete_old_version if version_max.present? && number_of_versions >= version_max
          Version.new(:version, self, snapshot, :model_classname => _classname, :instance_id => neo_id, :number => current_version)
        end
      end

      def converted_properties
        properties = self.props.reject{|key, value| key.to_sym == :_classname}
        properties.inject({}) { |h,(k,v)| h[k] = Neo4j::TypeConverters.to_java(self.class, k, v); h }
      end

      def number_of_versions
        Version.find(:model_classname => _classname, :instance_id => neo_id) {|query| query.size}
      end

      def each_versionable_relationship
        rule_relationships = java.util.HashSet.new(Neo4j::Rule::Rule.rule_names_for(_classname))
        self._java_node.getRelationships().each do |rel|
          yield rel unless rule_relationships.contains(rel.getType().name().to_sym) || rel.getType.name.to_sym == :version
        end
      end

      def create_version_relationship(rel,snapshot)
        create_relationship(self._java_node,snapshot._java_node, rel, relationship_type(rel.getType()))
      end

      def relationship_type(rel_type)
        org.neo4j.graphdb.DynamicRelationshipType.withName( "version_#{rel_type.name}" )
      end

      def restore_relationship_type(snapshot_rel_type)
        org.neo4j.graphdb.DynamicRelationshipType.withName( "#{snapshot_rel_type.name.gsub("version_","")}" )
      end

      def delete_old_version
        versions = Version.find(:model_classname => _classname).asc(:number)
        versions.first.del
        versions.close
      end

      def restore_relationships(snapshot)
        each_versionable_relationship{|rel| rel.del}
        snapshot._java_node.getRelationships().each do |rel|
          restore_relationship(rel,snapshot) unless rel.getType.name.to_sym == :version
        end
      end

      def restore_relationship(rel,snapshot)
        create_relationship(snapshot._java_node, self._java_node, rel, restore_relationship_type(rel.getType()))
      end

      def create_relationship(comparison_node,connection_node,rel, relationship_type)
        if (comparison_node == rel.getStartNode())
          connection_node.createRelationshipTo(rel.getEndNode(), relationship_type)
        else
          rel.getStartNode().createRelationshipTo(connection_node, relationship_type)
        end
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