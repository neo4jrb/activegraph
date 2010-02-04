module Neo4j
  module Relationships

    # Enables creating and traversal of nodes.
    # Includes the Enumerable Mixin.
    #
    class HasN
      include Enumerable

      def initialize(node, dsl, &filter) # :nodoc:
        @node = node
        @traverser = NodeTraverser.new(node._java_node)
        @outgoing = dsl.outgoing?
        # returns the other DSL if it exists otherwise use this DSL for specifing incoming relationships
        if @outgoing
          @dsl = dsl
        else
          # which class specifies the incoming DSL ?
          clazz = dsl.to_class || node.class
          @dsl = clazz.decl_relationships[dsl.to_type]
          raise "Unspecified outgoing relationship '#{dsl.to_type}' for incoming relationship '#{dsl.rel_id}' on class #{clazz}" if @dsl.nil?
        end

        if  @outgoing
          @traverser.outgoing(@dsl.namespace_type)
        else
          @traverser.incoming(@dsl.namespace_type)
        end

        @traverser.filter(&filter) unless filter.nil?
      end


      # Returns the relationships instead of the nodes.
      #
      # ==== Example
      # # return the relationship objects between the folder and file nodes:
      # folder.files.rels.each {|x| ...}
      #
      def rels
        Neo4j::Relationships::RelationshipDSL.new(@node._java_node, (@outgoing)? :outgoing : :incoming, @dsl.namespace_type)
      end

      # Sets the depth of the traversal.
      # Default is 1 if not specified.
      #
      # ==== Example
      #  morpheus.friends.depth(:all).each { ... }
      #  morpheus.friends.depth(3).each { ... }
      #  
      # ==== Arguments
      # d<Fixnum,Symbol>:: the depth or :all if traversing to the end of the network.
      # ==== Return
      # self
      # 
      # :api: public
      def depth(d)
        @traverser.depth(d)
        self
      end

      # Required by the Enumerable mixin.
      def each(&block)
        @traverser.each(&block)
      end


      # Returns true if there are no node in this type of relationship
      def empty?
        @traverser.empty?
      end

      # Return the first relationship or nil
      def first
        @traverser.first
      end

      # Creates a relationship instance between this and the other node.
      def new(other)
        create_rel(@node, other)
      end


      # Creates a relationship between this and the other node.
      #
      # ==== Example
      # 
      #   n1 = Node.new # Node has declared having a friend type of relationship
      #   n2 = Node.new
      #   n3 = Node.new
      #
      #   n1 << n2 << n3
      #
      # This is the same as:
      #
      #   n1.add_rel(:friends, n2)
      #   n1.add_rel(:friends, n3)
      #
      # ==== Returns
      # self
      #
      # :api: public
      def <<(other)
        create_rel(@node, other)
        self
      end


      def create_rel(node, other) # :nodoc:
        # If the are creating an incoming relationship we need to swap incoming and outgoing nodes
        if @outgoing
          from, to = node, other
        else
          from, to = other, node
        end

        rel = from.add_rel(@dsl.namespace_type, to, @dsl.relationship_class)

        # the from.neo_id is only used for cascade_delete_incoming since that node will be deleted when all the list items has been deleted.
        # if cascade_delete_outgoing all nodes will be deleted when the root node is deleted
        # if cascade_delete_incoming then the root node will be deleted when all root nodes' outgoing nodes are deleted
        rel[@dsl.cascade_delete_prop_name] = node.neo_id if @dsl.cascade_delete?
        rel
      end

    end

  end
end
