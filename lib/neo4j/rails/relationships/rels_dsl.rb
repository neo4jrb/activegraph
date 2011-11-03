module Neo4j
  module Rails
    module Relationships

      # Instances of this class is returned from the #rels, and generated accessor methods:
      # has_n and has_one.
      # Notice, this class is very similar to the Neo4j::Rails::Relationships::NodesDSL except that
      # if creates, finds relationships instead of nodes.
      #
      # ==== Example
      #   class Person < Neo4j::Rails::Model
      #      has_n(:friends)
      #   end
      #
      #   person = Person.find(...)
      #   person.friends_rels  #=> returns a Neo4j::Rails::Relationships::RelsDSL
      #   rel = person.friends_rels.create(relationship properties)
      #
      class RelsDSL
        include Enumerable
        include Neo4j::Paginate

        def initialize(storage, dir=:both)
          @storage = storage
          @dir = dir
        end


        # Same as Neo4j::Rails::Relationships::NodesDSL#build except that you specify the properties of the
        # relationships and it returns a relationship
        def build(attrs = {})
          node = @storage.build(attrs)
          @storage.create_relationship_to(node, @dir)
        end

        # Same as Neo4j::Rails::Relationships::NodesDSL#create except that you specify the properties of the
        # relationships and it returns a relationship
        def create(attrs = {})
          node = @storage.create(attrs)
          rel = @storage.create_relationship_to(node, @dir)
          node.save
          rel
        end

        # Connects this node with an already existing other node with a new relationship.
        # The relationship can optionally be given a hash of properties
        # Does not save it.
        # Returns the created relationship
        def connect(other_node, relationship_properties = nil)
          rel = @storage.create_relationship_to(other_node, @dir)
          rel.attributes = relationship_properties if relationship_properties
          rel
        end

        # Same as Neo4j::Rails::Relationships::NodesDSL#create! except that you specify the properties of the
        # relationships and it returns a relationship
        def create!(attrs)
          node = @storage.create(attrs)
          rel = @storage.create_relationship_to(node, @dir)
          node.save!
          rel
        end

        # Specifies that we want outgoing (undeclared) relationships.
        #
        # ==== Example
        #   class Thing < Neo4j::Rails::Model
        #   end
        #
        #   t = Thing.find(...)
        #   t.rels(:reltype).outgoing  # returns an enumerable of all outgoing relationship of type :reltype
        #
        def outgoing
          @dir = :outgoing
          self
        end

        # Returns incoming relationship See #outgoing
        def incoming
          @dir = :incoming
          self
        end

        def each(&block)
          @storage.each_rel(@dir, &block)
        end

        # Simply counts all relationships
        def size
          @storage.size(@dir)
        end

        # True if no relationship
        def empty?
          size == 0
        end

        # Destroys all relationships object. Will not destroy the nodes.
        def destroy_all
          each {|n| n.destroy}
        end

        # Delete all relationship.
        def delete_all
          each {|n| n.delete}
        end

        # Same as Neo4j::Rails::Relationships::NodesDSL#find except that it searches the relationships instead of
        # the nodes.
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

        # Same as Neo4j::Rails::Relationships::NodesDSL#all except that it searches the relationships instead of
        # the nodes.
        def all(*args)
          if args.first.class == Neo4j::Rails::Relationship #arg is a relationship
            find_all{|r| r == args.first}
          elsif ((args.first.is_a?(Integer) || args.first.is_a?(String)) && args.first.to_i > 0) #arg is an int
            find_all{|r| r.start_node.id.to_i == args.first.to_i || r.end_node.id.to_i == args.first.to_i}
          elsif node_in?(*args) #arg is a node
            find_all{|r| r.start_node == args.first || r.end_node == args.first}
          else #there either aren't any args, or we don't understand them
            collect
          end
        end

        # Same as Neo4j::Rails::Relationships::NodesDSL#first except that it searches the relationships instead of
        # the nodes.
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

        # Same as Neo4j::Rails::Relationships::NodesDSL#[] except that it returns the n:th relationship instead
        # of the n:th node
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
