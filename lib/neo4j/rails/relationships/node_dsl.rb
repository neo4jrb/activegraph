module Neo4j
  module Rails
    module Relationships

      class NodesDSL #:nodoc:
        include Enumerable

        def initialize(storage, dir)
          @storage = storage
          @dir = dir
        end

        def build(attrs)
          self << (node = @storage.build(attrs))
          node
        end

        def create(attrs)
          self << (node = @storage.create(attrs))
          node.save
          node
        end

        def create!(attrs)
          self << (node = @storage.create(attrs))
          node.save!
          node
        end

        def <<(other)
          @storage.create_relationship_to(other, @dir)
          self
        end

        def depth(d)
          adapt_to_traverser.depth(d)
        end

        def adapt_to_traverser
          Neo4j::Traversal::Traverser.new(@storage.node, @storage.rel_type, @dir)
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

        def find(*args, &block)
          return super(*args, &block) if block
          node = args.first
          enum = Enumerator.new(@storage, :each_rel, @dir)
          if @dir == :incoming
            enum.find{|r| r.start_node == node}
          else
            enum.find{|r| r.end_node == node}
          end
        end

        def destroy_all
          each {|n| n.destroy}
        end

        def delete_all
          each {|n| n.delete}
        end

        def size
          @storage.size(@dir)
        end

        alias :length :size

        def each(&block)
          @storage.each_node(@dir, &block)
        end

        def delete(*nodes)
          @storage.destroy_rels(@dir, *nodes)
        end

        def empty?
          size == 0 # TODO, performance: there are probably faster way of doing this
        end

        def to_s
          "Node dir: #{@dir}, #{@storage}"
        end
      end
    end
  end
end
