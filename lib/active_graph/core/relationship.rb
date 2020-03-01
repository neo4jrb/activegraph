require 'active_graph/core/wrappable'

module ActiveGraph
  module Core
    module Relationship
      def props; properties; end
      def neo_id; id; end
      def start_node_neo_id; start_node_id; end
      def end_node_neo_id; end_node_id; end
      def rel_type; type; end
    end
  end
end
