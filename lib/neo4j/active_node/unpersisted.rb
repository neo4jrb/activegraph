module Neo4j
  module ActiveNode
    module Unpersisted
      # The values in this Hash are returned and used outside by reference
      # so any modifications to the Array should be in-place
      def deferred_create_cache
        @deferred_create_cache ||= {}
      end

      def deferred_options_cache
        @deferred_options_cache ||= {}
      end

      def defer_create(association_name, object, options = {})
        clear_deferred_nodes_for_association(association_name) if options[:clear]

        deferred_options_for_association(association_name) << {verify: options[:verify]}
        deferred_nodes_for_association(association_name) << object
      end

      def deferred_nodes_for_association(association_name)
        deferred_create_cache[association_name.to_sym] ||= []
      end

      def deferred_options_for_association(association_name)
        deferred_options_cache[association_name.to_sym] ||= []
      end

      def pending_deferred_creations?
        !deferred_create_cache.values.all?(&:empty?)
      end

      def clear_deferred_nodes_for_association(association_name)
        deferred_options_for_association(association_name).clear
        deferred_nodes_for_association(association_name).clear
      end

      private

      def process_unpersisted_nodes!
        deferred_create_cache.dup.each do |association_name, nodes|
          association_proxy = association_proxy(association_name)

          options_array = deferred_options_for_association(association_name)

          nodes.each_with_index do |node, index|
            options = options_array[index]

            if node.respond_to?(:changed?)
              node.save if node.changed? || !node.persisted?
              fail "Unable to defer node persistence, could not save #{node.inspect}" unless node.persisted?
            end

            if options[:verify]
              association_proxy.add_relation! node
            else
              association_proxy << node
            end
          end
        end

        @deferred_create_cache = {}
      end
    end
  end
end
