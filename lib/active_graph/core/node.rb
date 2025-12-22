# frozen_string_literal: true

module ActiveGraph
  module Core
    module Node
      def labels
        @labels ||= super
      end
    end
  end
end
