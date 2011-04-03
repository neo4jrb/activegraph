module Neo4j
  module Rails
    module Relationships
      class RelsDSL
        include Enumerable

        def initialize(storage)
          @storage = storage
          @dir = :both
        end

        def outgoing
          @dir = :outgoing
          self
        end

        def incoming
          @dir = :incoming
          self
        end

        def each(&block)
          @storage.each_rel(@dir, &block)
        end

        def size
          @storage.size(@dir)
        end

        def empty?
          size == 0
        end
      end
    end
  end
end
