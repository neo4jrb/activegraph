# frozen_string_literal: true

module ActiveGraph
  module Core
    module Entity
      def neo_id
        element_id
      end

      def properties
        @properties ||= super
      end
    end
  end
end
