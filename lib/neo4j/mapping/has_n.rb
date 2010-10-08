module Neo4j
  module Mapping

    # Enables creating and traversal of nodes.
    # Includes the Enumerable Mixin.
    #
    class HasN
      include Enumerable
      include ToJava

      def initialize(node, dsl) # :nodoc:
        @node = node
        @direction = dsl.direction
        # returns the other DSL if it exists otherwise use this DSL for specifing incoming relationships
        if @direction == :outgoing
          @dsl = dsl
        else
          # which class specifies the incoming DSL ?
          clazz = dsl.to_class || node.class
          @dsl = clazz._decl_rels[dsl.to_type]
          raise "Unspecified outgoing relationship '#{dsl.to_type}' for incoming relationship '#{dsl.rel_id}' on class #{clazz}" if @dsl.nil?
        end

        @traverser = Neo4j::NodeTraverser.new(node._java_node, @dsl.namespace_type, @direction)
      end

      def size
        [*self].size
      end

      alias_method :length, :size

      def [](index)
        each_with_index {|node,i| break node if index == i}
      end

      # Pretend we are an array - this is neccessarly for Rails actionpack/actionview/formhelper to work with this
      def is_a?(type)
        # ActionView requires this for nested attributes to work
        return true if Array == type
        super
      end

      # Returns the relationships instead of the nodes.
      #
      # ==== Example
      # # return the relationship objects between the folder and file nodes:
      # folder.files.rels.each {|x| ...}
      #
      def rels
        Neo4j::RelationshipTraverser.new(@node._java_node, [@dsl.namespace_type], @direction)
      end

      # Sets the depth of the traversal.
      # Default is 1 if not specified.
      #
      # ==== Example
      #  morpheus.friends.depth(:all).each { ... }
      #  morpheus.friends.depth(3).each { ... }
      #  
      # ==== Arguments
      # d:: the depth or :all if traversing to the end of the network (symbol or fixnum)
      # ==== Return
      # self
      # 
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


      # Creates a relationship instance between this and the other node.
      # Returns the relationship object
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
      # ==== Returns
      # self
      #
      def <<(other)
        create_rel(@node, other)
        self
      end


      def create_rel(node, other) # :nodoc:
        # If the are creating an incoming relationship we need to swap incoming and outgoing nodes
        if @direction == :outgoing
          from, to = node, other
        else
          from, to = other, node
        end

        java_type = type_to_java(@dsl.namespace_type)
        rel = from._java_node.create_relationship_to(to._java_node, java_type)
        rel[:_classname] =  @dsl.relationship_class.to_s if @dsl.relationship_class

        # TODO - not implemented yet
        # the from.neo_id is only used for cascade_delete_incoming since that node will be deleted when all the list items has been deleted.
        # if cascade_delete_outgoing all nodes will be deleted when the root node is deleted
        # if cascade_delete_incoming then the root node will be deleted when all root nodes' outgoing nodes are deleted
        #rel[@dsl.cascade_delete_prop_name] = node.neo_id if @dsl.cascade_delete?
        rel.wrapper
      end

    end

  end
end
