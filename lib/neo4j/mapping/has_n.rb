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
        # returns the other DSL if it exists otherwise use this DSL for specifying incoming relationships
        if @direction == :outgoing
          @dsl = dsl
        else
          # which class specifies the incoming DSL ?
          clazz = dsl.to_class || node.class
          @dsl = clazz._decl_rels[dsl.to_type]
          raise "Unspecified outgoing relationship '#{dsl.to_type}' for incoming relationship '#{dsl.rel_id}' on class #{clazz}" if @dsl.nil?
        end
      end

      def to_s
        "HasN [#@direction, #{@node.neo_id} #{@dsl.namespace_type}]"
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

      # Required by the Enumerable mixin.
      def each(&block)
        @dsl.each_node(@node, @direction, &block)
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

      # Returns true if there are no node in this type of relationship
      def empty?
        first != nil
      end


      # Creates a relationship instance between this and the other node.
      # Returns the relationship object
      def new(other)
        @dsl.create_relationship_to(@node, other)
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
        @dsl.create_relationship_to(@node, other)
        self
      end
    end

  end
end
