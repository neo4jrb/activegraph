module Neo4j
  module Rails
    module Relationships

      class Relationship
        attr_reader :rel_type, :start_node, :end_node


        def initialize(rel_type, start_node, end_node, decl)
          @rel_type   = rel_type
          @start_node = start_node
          @end_node   = end_node
          @decl       = decl
        end

        def del
          @decl.del_rel(self)
        end

        def persist
          @start_node._java
        end

        def to_s
          "Rel [#{rel_type} start #{start_node} end #{end_node}]"
        end
      end
    end
  end
end
