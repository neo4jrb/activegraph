module Neo4j
  module Rails
    module Relationships
      # This is the Neo4j::Rails version of the Neo4j::HasN::DeclRelationshipDsl class used by Neo4j::NodeMixin#has_n and has_one
      #
      class DeclRelationshipDsl #:nodoc:
        def initialize(storage, dir)
          @storage = storage
          @dir = dir
        end

        def single_relationship(*)
          @storage.single_relationship(@dir)
        end

        def single_node(*)
          @storage.single_node(@dir)
        end

        def all_relationships(*)
          @storage.all_relationships(@dir)
        end


        def create_relationship_to(node, other)
          @storage.create_relationship_to(other, @dir)
        end

        def each_node(node, &block)
          @storage.each_node(@dir, &block)
        end
      end
    end
  end
end

