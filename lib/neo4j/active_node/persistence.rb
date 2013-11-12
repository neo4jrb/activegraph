module Neo4j::ActiveNode
  module Persistence

    def save
      node = _create_node(_properties)
      init_on_load(node, node.props)
    end

    def neo_id
      _persisted_node.neo_id if _persisted_node
    end

      def exist?
      _persisted_node && _persisted_node.exist?
    end

    def del
      _persisted_node && _persisted_node.del
    end

    def _create_node(*args)
      session = Neo4j::Session.current
      props = args[0] if args[0].is_a?(Hash)
      labels = self.class.respond_to?(:mapped_label_names) ? self.class.mapped_label_names : []
      session.create_node(props, labels)
    end

    module ClassMethods
      def create(props = {})
        new().tap do |obj|
          obj.init_on_new(props)
          obj.save
        end
      end
    end

  end

end