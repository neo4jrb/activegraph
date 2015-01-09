module Neo4j
  module ActiveNode
    module Dependent
      def dependent_children
        @dependent_children ||= []
      end

      attr_writer :called_by
    end
  end
end
