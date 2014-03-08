module Neo4j
  module ActiveNode
    module HasN

      # The object created by a has_n or has_one Neo4j::NodeMixin class method which enables creating and traversal of nodes.
      #
      # @see Neo4j::ActiveNode::HasN::ClassMethods
      class Nodes
        include Enumerable

        def initialize(node, decl_rel) # :nodoc:
          @node = node
          @decl_rel = decl_rel
        end

        def to_s
          "HasN::Nodes [#{@decl_rel.dir}, id: #{@node.neo_id} type: #{@decl_rel.rel_type} decl_rel:#{@decl_rel}]"
        end

        # Traverse the relationship till the index position
        # @return [Neo4j::ActiveMixin,Neo4j::Node,nil] the node at the given position
        def [](index)
          i = 0
          each { |x| return x if i == index; i += 1 }
          nil # out of index
        end

        # Pretend we are an array - this is necessarily for Rails actionpack/actionview/formhelper to work with this
        def is_a?(type)
          # ActionView requires this for nested attributes to work
          return true if Array == type
          super
        end

        # Required by the Enumerable mixin.
        def each
          @decl_rel.each_node(@node) { |n| yield n } # Should use yield here as passing &block through doesn't always work (why?)
        end

        # returns none wrapped nodes, you may get better performance using this method
        def _each
          @decl_rel._each_node(@node) { |n| yield n }
        end

        # Returns an real ruby array.
        def to_ary
          self.to_a
        end

        # Returns true if there are no node in this type of relationship
        def empty?
          first == nil
        end


        # Creates a relationship instance between this and the other node.
        # Returns the relationship object
        def create(other, relationship_props = {})
          @decl_rel.create_relationship_to(@node, other, relationship_props)
        end


        # Creates a relationship between this and the other node.
        #
        # @example Person includes the Neo4j::NodeMixin and declares a has_n :friends
        #
        #   p = Person.new # Node has declared having a friend type of relationship
        #   n1 = Node.new
        #   n2 = Node.new
        #
        #   p.friends << n2 << n3
        #
        # @return self
        def <<(other)
          @decl_rel.create_relationship_to(@node, other)
          self
        end
      end

    end
  end
end