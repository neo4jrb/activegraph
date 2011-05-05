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
          
          case args.first
            when :all, :first          
              kind = args.shift
              send(kind, *args)
            when "0", 0
              nil
            else
              if ((args.first.is_a?(Integer) || args.first.is_a?(String)) && args.first.to_i > 0)
                find_by_id(*args)
              else
                first(*args)
              end
          end          
        end

        def all(*args)
          unless args.empty?
            enum = Enumerator.new(@storage, :each_node, @dir).find{|n| n == args.first}
          else
            enum = Enumerator.new(@storage, :each_node, @dir)
          end
        end

        def first(*args)
          if result = all(*args)
            if result.respond_to?(:collect) #if it's enumerable, get the first result
              result.first
            else 
              result
            end
          else
            nil
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

        def blank?
          false unless size == 0
        end

        def to_s
          "Node dir: #{@dir}, #{@storage}"
        end
        
        protected


        def find_by_id(*args)
          result = Enumerator.new(@storage, :each_node, @dir).find{|n| n.id.to_i == args.first.to_i}        
        end
   
      end
    end
  end
end
