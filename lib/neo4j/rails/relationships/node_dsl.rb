module Neo4j
  module Rails
    module Relationships

      class NodesDSL #:nodoc:
        include Enumerable

        def initialize(storage, dir)
          @storage = storage
          @dir = dir
        end

        def <<(other)
          @storage.create_relationship_to(other, @dir)
          self
        end

        def size
          @storage.size(@dir)
        end

        def each(&block)
          @storage.each_node(@dir, &block)
        end
      end
    end
  end
end
