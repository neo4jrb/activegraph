require 'active_graph/runtime_registry'

module ActiveGraph
  module Railties
    module ControllerRuntime
      extend ActiveSupport::Concern

      private

      def process_action(*)
        ActiveGraph::RuntimeRegistry.reset
        super
      end

      def append_info_to_payload(payload)
        super

        payload[:db_runtime] = (payload[:db_runtime] || 0) + ActiveGraph::RuntimeRegistry.reset
      end
    end
  end
end