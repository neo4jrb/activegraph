module ActiveGraph
  module Shared
    module Identity
      def ==(other)
        other.class == self.class && other.id == id
      end

      alias eql? ==

      # Returns an Enumerable of all (primary) key attributes
      # or nil if model.persisted? is false
      def to_key
        _persisted_obj ? [id] : nil
      end

      # @return [String, nil] the neo4j id of the node if persisted or nil
      def element_id
        _persisted_obj&.element_id
      end

      alias neo_id element_id

      def id
        if self.class.id_property_name
          send(self.class.id_property_name)
        else
          # Relationship
          neo_id
        end
      end

      def hash
        id.hash
      end
    end
  end
end
