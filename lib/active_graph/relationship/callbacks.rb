module ActiveGraph
  module Relationship
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      include ActiveGraph::Shared::Callbacks

      def save(*args)
        unless _persisted_obj || (from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id))
          fail ActiveGraph::Relationship::Persistence::RelInvalidError, 'from_node and to_node must be node objects'
        end
        super(*args)
      end

      def destroy
        to_node.callbacks_from_relationship(self, :in, from_node).try(:last)
        from_node.callbacks_from_relationship(self, :out, to_node).try(:last)
        super
      end
    end
  end
end
