module Neo4j
  module Rails
    module RelationshipPersistence
      extend TxMethods

      # Initialize a Node with a set of properties (or empty if nothing is passed)
      def initialize(*args)
        return initialize_attributes(nil) if args.size < 3 # then we have been loaded
        type, start_node, end_node, attributes = args
        @_rel_type = type.to_sym
        raise "Unknown type" unless type
        raise "Unknown start_node" unless start_node
        raise "Unknown end_node" unless end_node
        self.start_node = start_node
        self.end_node = end_node
        initialize_attributes(attributes)
      end


      def create
        # prevent calling create twice
        @_start_node.add_unpersisted_outgoing_rel(rel_type, self)
        @_end_node.add_unpersisted_incoming_rel(rel_type, self)

        return unless _persist_node(@_start_node) && _persist_node(@_end_node)

        java_rel = Neo4j::Relationship.new(rel_type, start_node, end_node)
        init_on_load(java_rel)
        Neo4j::IdentityMap.add(java_rel, self)
        init_on_create

        @_start_node.rm_unpersisted_outgoing_rel(rel_type, self)
        @_end_node.rm_unpersisted_incoming_rel(rel_type, self)
        true
      end

      # @return [Symbol] the relationship type
      def rel_type
        new_record? ? @_rel_type : _java_entity.rel_type.to_sym
      end

      # @see http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Core/Relationship#other_node-instance_method
      def other_node(node)
        if persisted?
          _java_rel._other_node(node._java_entity)
        else
          @_start_node == node ? @_end_node : @_start_node
        end
      end

      # Returns the start node which can be unpersisted
      # @see http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Core/Relationship#start_node-instance_method
      def start_node
        @_start_node ||= _java_rel && _java_rel.start_node.wrapper
      end

      # Returns the end node which can be unpersisted
      # @see http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Core/Relationship#end_node-instance_method
      def end_node
        @_end_node ||= _java_rel && _java_rel.end_node.wrapper
      end

      # Reload the object from the DB
      def reload(options = nil)
        raise "Can't reload a none persisted node" if new_record?
        clear_changes
        reset_attributes
        unless reload_from_database
          set_deleted_properties
          freeze
        end
        self
      end


      def reload_from_database
        Neo4j::IdentityMap.remove_rel_by_id(id) if persisted?
        if reloaded = self.class.load_entity(id)
          send(:attributes=, reloaded.attributes, false)
        end
        reloaded
      end

      protected

      def start_node=(node)
        old = @_start_node
        @_start_node = node
        # TODO should raise exception if not persisted and changed
        if old != @_start_node
          old && old.rm_outgoing_rel(rel_type, self)
          @_start_node.class != Neo4j::Node && @_start_node.add_outgoing_rel(rel_type, self)
        end
      end

      def end_node=(node)
        old = @_end_node
        @_end_node = node
        # TODO should raise exception if not persisted and changed
        if old != @_end_node
          old && old.rm_incoming_rel(rel_type, self)
          @_end_node.class != Neo4j::Node && @_end_node.add_incoming_rel(rel_type, self)
        end
      end

      def _persist_node(start_or_end_node)
        ((start_or_end_node.new_record? || start_or_end_node.relationships_changed?) && !start_or_end_node.create_or_updating?) ? start_or_end_node.save : true
      end

    end

  end
end

