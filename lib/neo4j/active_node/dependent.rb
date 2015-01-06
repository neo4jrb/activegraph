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

      attr_writer :called_by
    end
  end
end
