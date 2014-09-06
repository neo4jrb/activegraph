module Neo4j
  module ActiveRel
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      include Neo4j::Shared::Callbacks

      def save(*args)
        unless from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id)
          raise Neo4j::ActiveRel::Persistence::RelInvalidError, 'from_node and to_node must be node objects'
        end 
        super(*args)
      end
    end
  end
end