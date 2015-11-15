module Neo4j::ActiveNode::HasN
  class Association
    class RelFactory
      [:start_object, :other_node_or_nodes, :properties, :association].tap do |accessors|
        attr_reader(*accessors)
        private(*accessors)
      end

      def self.create(start_object, other_node_or_nodes, properties, association)
        factory = new(start_object, other_node_or_nodes, properties, association)
        factory._create_relationship
      end

      def _create_relationship
        creator = association.relationship_class ? :rel_class : :factory
        send(:"_create_relationship_with_#{creator}")
      end

      private

      def initialize(start_object, other_node_or_nodes, properties, association)
        @start_object = start_object
        @other_node_or_nodes = other_node_or_nodes
        @properties = properties
        @association = association
      end

      def _create_relationship_with_rel_class
        Array(other_node_or_nodes).each do |other_node|
          node_props = _nodes_for_create(other_node, :from_node, :to_node)
          association.relationship_class.create!(properties.merge(node_props))
        end
      end

      def _create_relationship_with_factory
        Array(other_node_or_nodes).each do |other_node|
          wrapper = _rel_wrapper(properties)
          base = _match_query(other_node, wrapper)
          factory = Neo4j::Shared::RelQueryFactory.new(wrapper, wrapper.rel_identifier)
          factory.base_query = base
          factory.query.exec
        end
      end

      def _match_query(other_node, wrapper)
        nodes = _nodes_for_create(other_node, wrapper.from_node_identifier, wrapper.to_node_identifier)
        Neo4j::Session.current.query.match_nodes(nodes)
      end

      def _nodes_for_create(other_node, from_node_id, to_node_id)
        nodes = [@start_object, other_node]
        nodes.reverse! if association.direction == :in
        {from_node_id => nodes[0], to_node_id => nodes[1]}
      end

      def _rel_wrapper(properties)
        Neo4j::ActiveNode::HasN::Association::RelWrapper.new(association, properties)
      end
    end
  end
end
