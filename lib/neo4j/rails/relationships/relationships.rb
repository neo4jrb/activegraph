module Neo4j
  module Rails
    module Relationships


      def write_changed_relationships #:nodoc:
        @relationships.each_value do |storage|
          storage.persist
        end
      end

      def valid_relationships?(context, validated_origins) #:nodoc:
        puts " -- valid_relationships? for #{self}"
        validated_origins ||= [Set.new, self]
        !@relationships.values.find { |storage| !storage.valid?(context, validated_origins) }
      end

      def _decl_rels_for(rel_type) #:nodoc:
        dsl = super(rel_type)
        storage = _create_or_get_storage(dsl.rel_type, dsl.relationship_class)
        DeclRelationshipDsl.new(storage, dsl.dir)
      end

      def clear_relationships #:nodoc:
        @relationships = {}
      end

      
      def _create_or_get_storage(rel_type, relationship_class = nil)  #:nodoc:
        @relationships[rel_type.to_sym] ||= Storage.new(self, rel_type, relationship_class)
      end

      # If the node is persisted and it does not have any unsaved relationship it returns a Neo4j::NodeTraverser.
      # Otherwise it will return a NodesDSL which behaves like the Neo4j::NodeTraverser except that it does not
      # allow to traverse both persisted and not persisted (not saved yet) relationship more then depth one.
      #
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      #
      def outgoing(rel_type)
        storage = _create_or_get_storage(rel_type)
        if persisted? && !storage.modified?
          Neo4j::Traversal::Traverser.new(self).outgoing(rel_type)
        else
          NodesDSL.new(storage, :outgoing)
        end
      end


      def create_relationship_to(other_node, rel_type) #:nodoc:
        storage = _create_or_get_storage(rel_type.name)
        storage.create_relationship_to(other_node, :outgoing)
      end

      # Traverse or update an incoming relationship
      # See #outgoing
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      def incoming(rel_type)
        storage = _create_or_get_storage(rel_type)
        if persisted? && !storage.modified?
          Neo4j::Traversal::Traverser.new(self).incoming(rel_type)
        else
          NodesDSL.new(storage, :incoming)
        end
      end

      # See Neo4j::Rels#rels.
      # Will also allow to access unsaved relationships - like the #outgoing and #incoming method.
      #
      def rels(*rel_types)
        storage = _create_or_get_storage(rel_types.first)

        if persisted? && !storage.modified?
          super(*rel_types)
        else
          RelsDSL.new(storage)
        end
      end

      def add_outgoing_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).add_outgoing_rel(rel)
      end

      def add_incoming_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).add_incoming_rel(rel)
      end

      def rm_incoming_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).rm_incoming_rel(rel)
      end
    end
  end
end
