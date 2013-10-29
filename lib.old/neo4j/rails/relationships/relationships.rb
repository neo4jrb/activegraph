module Neo4j
  module Rails

    # This module overrides the {Neo4j::Core::Rels}[http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Core/Rels] and {Neo4j::Core::Traversal}[http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Core/Traversal]
    # modules so that it can handle unpersisted relationships of depth one.
    #
    module Relationships
      extend ActiveSupport::Concern

      included do
        # TODO THIS DOES NOT WORK
        alias_method :_core_rels, :rels
        alias_method :_core_rel, :rel
        alias_method :_core_rel?, :rel?
        alias_method :_core_outgoing, :outgoing
        alias_method :_core_incoming, :incoming
      end

      # Same as  {http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Core/Rels#outgoing-instance_method Neo4j::Core::Node#outgoing}
      # Since the incoming method is redefined we might need the neo4j-core version of this method.
      # @see #incoming
      # @api public
      def _outgoing(rel_type)
        _core_outgoing(rel_type)
      end

      # Same as  {http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Core/Rels#incoming-instance_method Neo4j::Core::Node#incoming}
      # Since the incoming method is redefined we might need the neo4j-core version of this method.
      # @see #incoming
      # @api public
      def _incoming(rel_type)
        _core_incomig(rel_type)
      end

      # Similar to {http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Core/Rels#outgoing-instance_method Neo4j::Core::Node#outgoing}
      # but allows traversing both persisted and unpersisted relationship of depth one.
      # For deeper or more advanced traversals see #_outgoing
      #
      # @example create a relationship between two nodes which is not persisted
      #  node.outgoing(:foo) << other_node
      #
      # @example create and persist a relationship between two nodes with given node
      #  node.outgoing(:foo) << other_node
      #  node.save
      #
      # @example create a new node with given attributes and persist the relationship
      #  node.outgoing(:foo).create(:name => 'bla')
      #
      # @example create a new node with given attributes and but do not  persist the relationship
      #  node.outgoing(:foo).new(:name => 'bla')
      #
      # @see #rels
      # @see #_outgoing
      # @api public
      # @param [String, Symbol] rel_type the relationship type we want to create or traverse
      # @return [NodesDSL]
      def outgoing(rel_type)
        storage = _create_or_get_storage(rel_type)
        NodesDSL.new(storage, :outgoing)
      end


      # Similar to {http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Core/Rels#incoming-instance_method Neo4j::Core::Node#incoming}
      # but allows traversing both persisted and unpersisted relationship of depth one.
      # See #outgoing
      # See, Neo4j::NodeRelationship#outgoing (when node is persisted) which returns a Neo4j::NodeTraverser
      # @param (see #outgoing)
      # @api public
      # @return [NodesDSL]
      def incoming(rel_type)
        storage = _create_or_get_storage(rel_type)
        NodesDSL.new(storage, :incoming)
      end

      # Allow to access persisted and unpersisted relationships - like the #outgoing and #incoming method.
      # To only find all the persisted relationship, node._java_entity.rels
      #
      # @example
      #   node.outgoing(:foo) << node2
      #   node.rels(:outgoing, :foo).outgoing #=> [node2]
      #   node.rels(:foo).incoming #=> []
      #   node.rels(:both) #=> [node2] - incoming and outgoing of any type
      #
      # @example All the relationships between me and another node of given dir & type
      #   me.rels(:outgoing, :friends).to_other(node)
      #
      # @param [:both, :incoming, :outgoing] dir the direction of the relationship
      # @param [String, Symbol] rel_type the requested relationship types we want look for, if none it gets relationships of any type
      # @return [RelsDSL, AllRelsDsl] an object which included the Ruby Enumerable mixin
      # @note it can return an unpersisted relationship
      def rels(dir=:both, rel_type=nil)
        raise "Illegal argument, first argument must be :both, :incoming or :outgoing, got #{dir.inspect}" unless [:incoming, :outgoing, :both].include?(dir)
        if rel_type.nil?
          AllRelsDsl.new(@_relationships, _java_node, dir)
        else
          storage = _create_or_get_storage(rel_type)
          RelsDSL.new(storage, dir)
        end
      end

      # Returns the only relationship of a given type and direction that is attached to this node, or nil.
      # This is a convenience method that is used in the commonly occuring situation where a node has exactly zero or
      # one relationships of a given type and direction to another node.
      # Typically this invariant is maintained by the rest of the code: if at any time more than one such relationships
      # exist, it is a fatal error that should generate an unchecked exception. This method reflects that semantics and
      # returns either:
      #
      # * nil if there are zero relationships of the given type and direction,
      # * the relationship if there's exactly one, or
      # * raise an exception in all other cases.
      # @param [:both, :incoming, :outgoing] dir the direction of the relationship
      # @param [Symbol, String] rel_type the type of relationship, see Neo4j::Core::Relationship#rel_type
      # @return [Neo4j::Relationship, nil, Neo4j::Rails::Relationship] the Relationship or wrapper for the Relationship or nil
      # @raise an exception if more then one relationship of given type and direction was found
      # @note it can return an unpersisted relationship
      def rel(dir, rel_type)
        raise "Illegal argument, first argument must be :both, :incoming or :outgoing, got #{dir.inspect}" unless [:incoming, :outgoing, :both].include?(dir)
        storage = _create_or_get_storage(rel_type)
        storage.single_relationship(dir)
      end

      # Check if the given relationship exists
      # Returns true if there are one or more relationships from this node to other nodes
      # with the given relationship.
      #
      # @param [:both, :incoming, :outgoing] dir  optional default :both (either, :outgoing, :incoming, :both)
      # @param [String,Symbol] rel_type the key and value to be set, default any type
      # @return [Boolean] true if one or more relationships exists for the given type and dir otherwise false
      def rel?(dir=:both, rel_type=nil)
        raise "Illegal argument, first argument must be :both, :incoming or :outgoing, got #{dir.inspect}" unless [:incoming, :outgoing, :both].include?(dir)
        storage = _create_or_get_storage(rel_type)
        !!storage.single_relationship(dir)
      end


      # Works like #rels method but instead returns the nodes.
      # It does try to load a Ruby wrapper around each node
      # @param (see #rels)
      # @return [Enumerable] an Enumeration of either Neo4j::Node objects or wrapped Neo4j::Node objects
      # @notice it's possible that the same node is returned more then once because of several relationship reaching to the same node, see #outgoing for alternative
      def nodes(dir, rel_type)
        raise "Illegal argument, first argument must be :both, :incoming or :outgoing, got #{dir.inspect}" unless [:incoming, :outgoing, :both].include?(dir)
        storage = _create_or_get_storage(rel_type)
        NodesDSL.new(storage, dir)
      end

      # Returns the only node of a given type and direction that is attached to this node, or nil.
      # This is a convenience method that is used in the commonly occuring situation where a node has exactly zero or one relationships of a given type and direction to another node.
      # Typically this invariant is maintained by the rest of the code: if at any time more than one such relationships exist, it is a fatal error that should generate an exception.
      # This method reflects that semantics and returns either:
      # * nil if there are zero relationships of the given type and direction,
      # * the relationship if there's exactly one, or
      # * throws an unchecked exception in all other cases.
      #
      # This method should be used only in situations with an invariant as described above. In those situations, a "state-checking" method (e.g. #rel?) is not required,
      # because this method behaves correctly "out of the box."
      #
      # @param (see #rel)
      # @see Neo4j::Core::Node#wrapper #wrapper - The method used to wrap the node in a Ruby object if the node was found
      def node(dir, rel_type)
        raise "Illegal argument, first argument must be :both, :incoming or :outgoing, got #{dir.inspect}" unless [:incoming, :outgoing, :both].include?(dir)
        storage = _create_or_get_storage(rel_type)
        storage.single_node(dir)
      end


      # @private
      def initialize_relationships
        @_relationships = {}
      end

      # @private
      def write_changed_relationships #:nodoc:
        @_relationships.each_value do |storage|
          storage.persist
        end
      end

      # @private
      def relationships_changed?
        @_relationships.each_value do |storage|
          return true if !storage.persisted?
        end
        false
      end

      # @private
      def clear_relationships
        @_relationships && @_relationships.each_value { |storage| storage.remove_from_identity_map }
        initialize_relationships
      end

      # @private
      def add_outgoing_rel(rel_type, rel)
        _create_or_get_storage(rel_type).add_outgoing_rel(rel)
      end

      # @private
      def add_incoming_rel(rel_type, rel)
        _create_or_get_storage(rel_type).add_incoming_rel(rel)
      end

      # @private
      def add_unpersisted_incoming_rel(rel_type, rel)
        if (storage = _create_or_get_storage(rel_type))
          # move the relationship since we are now about to store the relationship
          storage.add_unpersisted_incoming_rel(rel)
          storage.rm_incoming_rel(rel)
        end
      end

      # @private
      def add_unpersisted_outgoing_rel(rel_type, rel)
        if (storage = _create_or_get_storage(rel_type))
          # move the relationship since we are now about to store the relationship
          storage.add_unpersisted_outgoing_rel(rel)
          storage.rm_outgoing_rel(rel)
        end
      end

      # @private
      def rm_unpersisted_outgoing_rel(rel_type, rel)
        if (storage = _storage_for(rel_type))
          storage.rm_unpersisted_outgoing_rel(rel)
        end
      end

      # @private
      def rm_unpersisted_incoming_rel(rel_type, rel)
        if (storage = _storage_for(rel_type))
          storage.rm_unpersisted_incoming_rel(rel)
        end
      end

      protected

      def rm_incoming_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).rm_incoming_rel(rel)
      end

      def rm_outgoing_rel(rel_type, rel) #:nodoc:
        _create_or_get_storage(rel_type).rm_outgoing_rel(rel)
      end

      def _create_or_get_storage(rel_type) #:nodoc:
        @_relationships[rel_type.to_sym] ||= Storage.new(self, rel_type)
      end

      def _create_or_get_storage_for_decl_rels(decl_rels) #:nodoc:
        @_relationships[decl_rels.rel_type.to_sym] ||= Storage.new(self, decl_rels.rel_type, decl_rels)
      end

      def _storage_for(rel_type) #:nodoc:
        @_relationships[rel_type.to_sym]
      end


    end
  end
end
