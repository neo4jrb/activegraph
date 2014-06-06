module Neo4j
  module ActiveNode
    module HasN
      class Rels
        include Enumerable

        def initialize(node, decl_rel)
          @node = node
          @decl_rel = decl_rel
        end

        def to_s
          "HasN::Nodes [#{@decl_rel.dir}, id: #{@node.neo_id} type: #{@decl_rel.rel_type} decl_rel:#{@decl_rel}]"
        end

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

        def each
          @decl_rel.each_rel(@node) { |n| yield n } # Should use yield here as passing &block through doesn't always work (why?)
        end

        def to_ary
          self.to_a
        end

        def empty?
          first == nil
        end

        def build(rel_props={}, other_props={})
          if klass = @decl_rel.rel_class
            rel = klass.new(rel_props)
            other = @decl_rel.target_class.new(other_props)

            rel.start_node, rel.end_node = @decl_rel.incoming? ? [other, @node] : [@node, other]
            rel
          end
        end

        def where(conditions={})
          match = {between_labels: @decl_rel.target_name,
                   dir: @decl_rel.incoming? ? :incoming : :outgoing,
                   conditions: {}}

          conditions.each {|k,v| match[:conditions]["r.#{k}"] = v}

          @node.rels(match)
        end
      end
    end
  end
end

