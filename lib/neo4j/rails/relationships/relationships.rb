module Neo4j
  module Rails
    module Relationships


      def write_changed_relationships #:nodoc:
        @relationships.each_value do |storage|
          storage.persist
        end
      end

      def valid_relationships?(context, validated_nodes) #:nodoc:
        validated_nodes ||= Set.new
        !@relationships.values.find { |storage| !storage.valid?(context, validated_nodes) }
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

      # If the node is persisted it returns a Neo4j::NodeTraverser
      # otherwise create a new object which will handle creating new relationships in memory.
      # If not persisted the traversal method like prune, expand, filter etc. will not be available
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


      def create_relationship_to(other_node, rel_type)
        storage = _create_or_get_storage(rel_type.name)
        storage.create_relationship_to(other_node, :outgoing)
      end

      def incoming(rel_type)
        storage = _create_or_get_storage(rel_type)
        if persisted? && !storage.modified?
          Neo4j::Traversal::Traverser.new(self).incoming(rel_type)
        else
          NodesDSL.new(storage, :incoming)
        end
      end

      def rels(*rel_types)
        storage = _create_or_get_storage(rel_types.first)

        if persisted? && !storage.modified?
          super(*rel_types)
        else
          RelsDSL.new(storage)
        end
      end

      def add_outgoing_rel(rel_type, rel)
        _create_or_get_storage(rel_type).add_outgoing_rel(rel)
      end

      def add_incoming_rel(rel_type, rel)
        _create_or_get_storage(rel_type).add_incoming_rel(rel)
      end

      def rm_incoming_rel(rel_type, rel)
        _create_or_get_storage(rel_type).rm_incoming_rel(rel)
      end
    end
  end
end
