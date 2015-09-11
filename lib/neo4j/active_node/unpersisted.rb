module Neo4j
  module ActiveNode
    module Unpersisted
      def pending_associations
        @pending_associations ||= []
      end

      def pending_associations?
        !@pending_associations.blank?
      end

      private

      # TODO: Change this method's name.
      # Takes the pending_associations hash, which is in the format { cache_key => [:association_name, :association_operator]},
      # and returns them as { association_name => [[nodes_for_persistence], :operator] }
      def pending_associations_with_nodes
        return unless pending_associations?
        {}.tap do |deferred_nodes|
          pending_associations.uniq.each do |association_name|
            nodes_for_creation = association_proxy(association_name)
            nodes_for_creation = nodes_for_creation.reject(&:persisted?) if self.persisted?

            deferred_nodes[association_name] = nodes_for_creation
          end
        end
      end

      # @param [Hash] deferred_nodes A hash created by :pending_associations_with_nodes
      def process_unpersisted_nodes!(deferred_nodes)
        deferred_nodes.each_pair do |k, v|
          save_and_associate_queue(k, v)
        end
      end


      def save_and_associate_queue(association_name, node_queue)
        association_proc = proc { |node| save_and_associate_node(association_name, node) }
        node_queue.each do |element|
          element.is_a?(Array) ? element.each { |node| association_proc.call(node) } : association_proc.call(element)
        end
      end

      def save_and_associate_node(association_name, node)
        if node.respond_to?(:changed?)
          node.save if node.changed? || !node.persisted?
          fail "Unable to defer node persistence, could not save #{node.inspect}" unless node.persisted?
        end
        association_proxy(association_name) << node
      end
    end
  end
end
