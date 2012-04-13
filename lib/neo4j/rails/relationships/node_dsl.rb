module Neo4j
  module Rails
    module Relationships

      # Instances of this class is returned from the #outgoing, #incoming and generated accessor methods:
      # has_n and has_one.
      # Notice that this class includes the Ruby Enumerable mixin.
      # If you want to full traversal api use the core version of these methods (some_node._outgoing(...)).
      #
      class NodesDSL
        include Enumerable

        def initialize(storage, dir)
          @storage = storage
          @dir = dir
        end

        # Creates a new node given the specified attributes and connect it with a relationship.
        # The new node and relationship will not be saved.
        # Both the relationship class and the node class can be specified with the has_n and has_one.
        #
        # @example
        #   class Person < Neo4j::RailsNode
        #      has_n(:friends).to(Person).relationship(Friend)
        #      has_n(:knows)
        #   end
        #
        #   Person.friends.build(:name => 'kalle')  # creates a Person and Friends class.
        #   Person.knows.build(:name => 'kalle') # creates a Neo4j::RailsNode and Neo4j::RailsRelationship class
        # @param [Hash] attrs the attributes for the created node
        # @return [Neo4j::RailsNode]
        def build(attrs = {})
          self << (node = @storage.build(attrs))
          node
        end

        # Same as #build except that the relationship and node are saved.
        # @param (see #build)
        # @return [Neo4j::RailsNode]
        def create(attrs = {})
          self << (node = @storage.create(attrs))
          node.save
          node
        end

        # Same as #create but will raise an exception if an error (like validation) occurs.
        # @param (see #build)
        # @return [Neo4j::RailsNode]
        def create!(attrs)
          self << (node = @storage.create(attrs))
          node.save!
          node
        end

        # Adds a new node to the relationship, no transaction is needed.
        #
        # @example create a relationship between two nodes
        #   node.friends << other
        #
        # @example using existing nodes
        #   node.friends = ['42', '32']
        #
        # @param [String, Neo4j::RailsNode] other
        # @return self
        def <<(other)
          if other.is_a?(String)
            # this is typically called in an assignment operator, person.friends = ['42', '32']
            node = Neo4j::Node.load(other)
            @storage.create_relationship_to(node, @dir) unless all.include?(node)
          else
            # allow multiple relationships to the same node
            @storage.create_relationship_to(other, @dir)
          end
          self
        end

        def persisted?
          @storage.persisted?
        end

        def to_ary
          all.to_a
        end

        # Returns the n:th item in the relationship.
        # This method simply traverse all relationship and returns the n:th one.
        def [](index)
          i = 0
          each { |x| return x if i == index; i += 1 }
          nil # out of index
        end

        def is_a?(type)
          # ActionView requires this for nested attributes to work
          return true if Array == type
          super
        end

        # Find one node in the relationship.
        #
        # @example Declaration of the relationship used in the examples below
        #
        #   class Actor < Neo4j::RailsNode
        #     has_n(:acted_in)
        #   end
        #
        # @example find all child nodes
        #   actor.acted_in.find(:all)
        #
        # @example find first child node
        #   actor.acted_in.find(:first)
        #
        # @example find a child node by node
        #   actor.acted_in.find(some_movie)
        #
        # @example find a child node by id" do
        #   actor.acted_in.find(some_movie.id)
        #
        # @example find a child node by delegate to Enumerable#find
        #   actor.acted_in.find{|n| n.title == 'movie_1'}
        #
        # @return [Neo4j::RailsNode]
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
            enum = Enumerator.new(@storage, :each_node, @dir).find { |n| n == args.first }
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

        # Destroys all nodes (!) and relationship.
        # Notice, if you only want to destroy the relationship use the #rels(:friends).destroy_all method instead.
        def destroy_all
          each { |n| n.destroy }
        end

        # Deletes all nodes and relationships, similar to #destroy_all
        def delete_all
          each { |n| n.delete }
        end

        # Counts all relationships
        def count
          @storage.count(@dir)
        end

        alias :length :count

        def each
          @storage.each_node(@dir) { |n| yield n } # Why passing the &block through doesn't work on JRuby 1.9?
        end

        # Delete relationships to the given nodes
        # @param [Neo4j::RailsNode] nodes a list of nodes we want to delete relationships to
        def delete(*nodes)
          @storage.destroy_rels(@dir, *nodes)
        end

        def empty?
          !@storage.relationships?(@dir)
        end

        def blank?
          false unless empty?
        end

        def to_s
          "Node dir: #{@dir}, #{@storage}"
        end

        def rel_changed?
          @storage.persisted?
        end


        # These methods are using the Neo4j::Core::Traversal::Traverser which means that only persisted relationship will be seen
        # but more advanced traversal can be performed.
        CORE_TRAVERSAL_METHODS = [:depth, :outgoing, :incoming, :both, :expand, :depth_first, :breadth_first, :eval_paths, :unique, :expander, :prune, :filter, :include_start_node, :rels, :eval_paths]


        protected

        def self.define_traversal_method(method_name)
          class_eval <<-RUBY, __FILE__, __LINE__
						def #{method_name}(*args, &block)
              if block
							  Neo4j::Core::Traversal::Traverser.new(@storage.node, @dir, @storage.rel_type).send(:"#{method_name}", *args, &block)
              else
              	Neo4j::Core::Traversal::Traverser.new(@storage.node, @dir, @storage.rel_type).send(:"#{method_name}", *args)
              end
						end
          RUBY
        end

        CORE_TRAVERSAL_METHODS.each { |meth| define_traversal_method(meth)}

        def find_by_id(*args)
          result = Enumerator.new(@storage, :each_node, @dir).find { |n| n.id.to_i == args.first.to_i }
        end

      end
    end
  end
end
