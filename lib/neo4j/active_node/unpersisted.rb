module Neo4j
  module ActiveNode
    module Unpersisted
      def pending_associations
        @pending_associations ||= {}
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
          pending_associations.each_pair do |cache_key, (association_name, operator)|
            nodes_for_creation = self.persisted? ? association_proxy_cache[cache_key].select { |n| !n.persisted? } : association_proxy_cache[cache_key]
            deferred_nodes[association_name] = [nodes_for_creation, operator]
          end
        end
      end

      # @param [Hash] deferred_nodes A hash created by :pending_associations_with_nodes
      def process_unpersisted_nodes!(deferred_nodes)
        deferred_nodes.each_pair do |k, (v, o)|
          save_and_associate_queue(k, v, o)
        end
      end


      def save_and_associate_queue(association_name, node_queue, operator)
        association_proc = proc { |node| save_and_associate_node(association_name, node, operator) }
        node_queue.each do |element|
          element.is_a?(Array) ? element.each { |node| association_proc.call(node) } : association_proc.call(element)
        end
      end

      def save_and_associate_node(association_name, node, operator)
        if node.respond_to?(:changed?)
          node.save if node.changed? || !node.persisted?
          fail "Unable to defer node persistence, could not save #{node.inspect}" unless node.persisted?
        end
        operator == :<< ? send(association_name).send(operator, node) : send(:"#{association_name}=", node)
      end
    end
  end
end
