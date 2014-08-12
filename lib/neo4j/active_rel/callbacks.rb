module Neo4j
  module ActiveRel
    module Callbacks #:nodoc:
      extend ActiveSupport::Concern
      include Neo4j::Library::Callbacks

      def save(*args)
        raise Neo4j::ActiveRel::Persistence::RelInvalidError.new(self) unless self.persisted? || (from_node.respond_to?(:neo_id) && to_node.respond_to?(:neo_id))
        super(*args)
      end
    end
  end
end