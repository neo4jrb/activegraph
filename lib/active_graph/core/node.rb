# frozen_string_literal: true

module ActiveGraph
  module Core
    module Node
      def neo_id
        id
      end

      def labels
        @labels ||= super
      end
    end
  end
end
