module Neo4j
  module Rails
    module Relationships

      # Instances of this class is returned from the #outgoing, #incoming and generated accessor methods:
      # has_n and has_one.
      # Notice that this class includes the Ruby Enumerable mixin.
      # If you want to full traversal api use the wrapped java node instead (some_node._java_node.outgoing(...)).
      #
      class NodesDSL
        include Enumerable
        include Neo4j::Paginate

        def initialize(storage, dir)
          @storage = storage
          @dir = dir
        end

        # Creates a new node given the specified attributes and connect it with a relationship.
        # The new node and relationship will not be saved.
        # Both the relationship class and the node class can be specified with the has_n and has_one.
        #
        # ==== Example
        #
        #   class Person < Neo4j::Rails::Model
        #      has_n(:friends).to(Person).relationship(Friend)
        #      has_n(:knows)
        #   end
        #
        #   Person.friends.build(:name => 'kalle')  # creates a Person and Friends class.
        #   Person.knows.build(:name => 'kalle') # creates a Neo4j::Rails::Model and Neo4j::Rails::Relationship class
        #
        def build(attrs =  {})
          self << (node = @storage.build(attrs))
          node
        end

        # Same as #build except that the relationship and node are saved.
        def create(attrs = {})
          self << (node = @storage.create(attrs))
          node.save
          node
        end

        # Same as #create but will raise an exception if an error (like validation) occurs.
        def create!(attrs)
          self << (node = @storage.create(attrs))
          node.save!
          node
        end

        # Adds a new node to the relationship
        def <<(other)
          @storage.create_relationship_to(other, @dir)
          self
        end

        def persisted?
          @storage.persisted?
        end

        def to_ary
          all.to_a
        end

        # Specifies the depth of the traversal
        def depth(d)
          adapt_to_traverser.depth(d)
        end

        def adapt_to_traverser # :nodoc:
          Neo4j::Traversal::Traverser.new(@storage.node, @storage.rel_type, @dir)
        end

        # Returns the n:th item in the relationship.
        # This method simply traverse all relationship and returns the n:th one.
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

        # Find one node in the relationship.
        #
        # ==== Example
        #
        #   class Actor < Neo4j::Rails::Model
        #     has_n(:acted_in)
        #   end
        #
        #    # find all child nodes
        #    actor.acted_in.find(:all)
        #
        #    # find first child node
        #    actor.acted_in.find(:first)
        #
        #    # find a child node by node
        #    actor.acted_in.find(some_movie)
        #
        #    # find a child node by id" do
        #    actor.acted_in.find(some_movie.id)
        #
        #    #find a child node by delegate to Enumerable#find
        #    actor.acted_in.find{|n| n.title == 'movie_1'}
        #
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

        # Same as #find except that it returns an Enumerator of all nodes found.
        #
        def all(*args)
          unless args.empty?
            enum = Enumerator.new(@storage, :each_node, @dir).find{|n| n == args.first}
          else
            enum = Enumerator.new(@storage, :each_node, @dir)
          end
        end

        #  Returns first node in the relationship specified by the arguments or returns nil.
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

        # Destroys all nodes (!!!) and relationship in this relatationship.
        # Notice, if you only want to destroy the relationship use the
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
