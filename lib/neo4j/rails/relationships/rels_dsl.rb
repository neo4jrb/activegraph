module Neo4j
  module Rails
    module Relationships
      class RelsDSL
        include Enumerable

        def initialize(storage, dir=:both)
          @storage = storage
          @dir = dir
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

        def find(*args, &block)
          return super(*args, &block) if block
          node = args.first
          if @dir == :incoming
            find{|r| r.start_node == node}
          else
            find{|r| r.end_node == node}
          end
        end

        def [](index)
          i = 0
          each{|x| return x if i == index; i += 1}
          nil # out of index
        end

        def is_a?(type)
          # ActionView requires this for nested attributes to work
          return true if Array == type
          super
        end

        def to_s
          "Rels dir: #{@dir}, #{@storage}"
        end

      end
    end
  end
end
