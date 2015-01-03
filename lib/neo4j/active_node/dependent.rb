module Neo4j
  module ActiveNode
    module Dependent

      # duck for has_one
      def each_for_destruction(_)
        self
      end

      def dependent_children
        @dependent_children ||= []
      end

      def called_by=(node)
        @called_by = node
      end
    end
  end
end
