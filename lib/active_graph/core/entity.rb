# frozen_string_literal: true

module ActiveGraph
  module Core
    module Entity
      def properties
        @properties ||= super
      end
    end
  end
end
