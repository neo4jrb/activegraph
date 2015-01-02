module Neo4j
  module ActiveNode
    module Dependent
      def dependent_children
        @dependent_children ||= []
      end

      def called_by=(node)
        @called_by = node
      end
    end
  end
end
