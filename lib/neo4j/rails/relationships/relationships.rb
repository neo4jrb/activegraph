module Neo4j
  module Rails
    module Relationships

      def write_changed_relationships #:nodoc:
        @_relationships.each_value do |storage|
          storage.persist
        end
      end

      def relationships_changed?
        @_relationships.each_value do |storage|
          return true if !storage.persisted?
        end
        false
      end

      def clear_relationships #:nodoc:
        @_relationships && @_relationships.each_value{|storage| storage.remove_from_identity_map}
        @_relationships = {}
      end


      def _create_or_get_storage(rel_type) #:nodoc:
        dsl = _decl_rels_for(rel_type.to_sym)
        @_relationships[rel_type.to_sym] ||= Storage.new(self, rel_type, dsl)
      end

      def _create_or_get_storage_for_decl_rels(decl_rels) #:nodoc:
        @_relationships[decl_rels.rel_type.to_sym] ||= Storage.new(self, decl_rels.rel_type, decl_rels)
      end

      def _storage_for(rel_type) #:nodoc:
        @_relationships[rel_type.to_sym]
      end

      # If the node is persisted and it does not have any unsaved relationship it returns a Neo4j::NodeTraverser.
      # Otherwise it will return a NodesDSL which behaves like the Neo4j::NodeTraverser except that it does not
      # allow to traverse both persisted and not persisted (not saved yet) relationship more then depth one.
      #
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      #
      def outgoing(rel_type)
        storage = _create_or_get_storage(rel_type)
        NodesDSL.new(storage, :outgoing)
      end


      # Traverse or update an incoming relationship
      # See #outgoing
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      def incoming(rel_type)
        storage = _create_or_get_storage(rel_type)
        NodesDSL.new(storage, :incoming)
      end

      # See Neo4j::Rels#rels.
      #
      # Will also allow to access unsaved relationships - like the #outgoing and #incoming method.
      # It one argument - the relationship type.
      #
      # To only find all the persisted relationship, node._java_node.rels
      #
      # === Example
      #
      #   node.outgoing(:foo) << node2
      #   node.rels(:foo).outgoing #=> [node2]
      #   node.rels(:foo).incoming #=> []
      #   node.rels(:foo) #=> [node2] - incoming and outgoing
      #
      def rels(*rel_types)
        if rel_types.empty?
          AllRelsDsl.new(@_relationships, _java_node)
        else
          storage = _create_or_get_storage(rel_types.first)
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

      def rm_outgoing_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).rm_outgoing_rel(rel)
      end

      def rm_outgoing_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).rm_outgoing_rel(rel)
      end

      def add_unpersisted_incoming_rel(rel_type, rel) #:nodoc
        if (storage = _create_or_get_storage(rel_type))
          # move the relationship since we are now about to store the relationship
          storage.add_unpersisted_incoming_rel(rel)
          storage.rm_incoming_rel(rel)
        end
      end

      def add_unpersisted_outgoing_rel(rel_type, rel) #:nodoc
        if (storage = _create_or_get_storage(rel_type))
          # move the relationship since we are now about to store the relationship
          storage.add_unpersisted_outgoing_rel(rel)
          storage.rm_outgoing_rel(rel)
        end
      end

      def rm_unpersisted_outgoing_rel(rel_type, rel)  #:nodoc
        if (storage = _storage_for(rel_type))
          storage.rm_unpersisted_outgoing_rel(rel)
        end
      end

      def rm_unpersisted_incoming_rel(rel_type, rel)  #:nodoc
        if (storage = _storage_for(rel_type))
          storage.rm_unpersisted_incoming_rel(rel)
        end
      end


    end
  end
end
