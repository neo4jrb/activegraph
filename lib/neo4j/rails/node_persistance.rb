module Neo4j
  module Rails
    module NodePersistence
      extend TxMethods

      def initialize(attributes = nil)
        initialize_relationships
        initialize_attributes(attributes)
      end


      def create
        node = Neo4j::Node.new
        init_on_load(node)
        Neo4j::IdentityMap.add(node, self)
        init_on_create
        write_changed_relationships
        clear_relationships
        true
      end

      def update
        super
        write_changed_relationships
        clear_relationships
        true
      end

      # Reload the object from the DB
      def reload(options = nil)
        # Can't reload a none persisted node
        return if new_record?
        clear_changes
        clear_relationships
        clear_composition_cache
        reset_attributes
        unless reload_from_database
          set_deleted_properties
          freeze
        end
        self
      end


      def reload_from_database
        Neo4j::IdentityMap.remove_node_by_id(neo_id)
        if reloaded = self.class.load_entity(neo_id)
          send(:attributes=, reloaded.attributes, false)
        end
        reloaded
      end


    end
  end
end
