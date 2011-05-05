module Neo4j
  module Rails
    module Relationships
      class RelsDSL
        include Enumerable

        def initialize(storage, dir=:both)
          @storage = storage
          @dir = dir
        end


        def build(attrs)
          node = @storage.build(attrs)
          @storage.create_relationship_to(node, @dir)
        end

        def create(attrs)
          node = @storage.create(attrs)
          rel = @storage.create_relationship_to(node, @dir)
          node.save
          rel
        end

        def create!(attrs)
          node = @storage.create(attrs)
          rel = @storage.create_relationship_to(node, @dir)
          node.save!
          rel
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

        def destroy_all
          each {|n| n.destroy}
        end

        def delete_all
          each {|n| n.delete}
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
          if args.first.class == Neo4j::Rails::Relationship #arg is a relationship
            find{|r| r == args.first}
          elsif ((args.first.is_a?(Integer) || args.first.is_a?(String)) && args.first.to_i > 0) #arg is an int
            find{|r| r.start_node.id.to_i == args.first.to_i || r.end_node.id.to_i == args.first.to_i}
          elsif node_in?(*args) #arg is a node
            find{|r| r.start_node == args.first || r.end_node == args.first}
          else #there either aren't any args, or we don't understand them
            collect
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

        protected

        def node_in?(*args)
          # does it contain an string, which will be treated like a condition ?
          if args.find { |a| a.class.superclass == Neo4j::Rails::Model }
            return true 
          else
            return false
          end
        end

        def find_by_id(*args)
          find{|r| r.id.to_i == args.first.to_i}       
        end


      end
    end
  end
end
