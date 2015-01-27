module Neo4j
  module ActiveNode
    module Dependent
      # When a `dependent: :destroy` action occurs, this array holds objects preparing for deletion.
      def dependent_children
        @dependent_children ||= []
      end

      # \@called_by is used association dependency to prevent loops
      attr_accessor :called_by
    end
  end
end
