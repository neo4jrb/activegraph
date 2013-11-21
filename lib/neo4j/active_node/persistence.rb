module Neo4j::ActiveNode
  module Persistence

    def save
      node = _create_node(persistable_attributes)
      init_on_load(node, node.props)
    end

    def neo_id
      _persisted_node.neo_id if _persisted_node
    end

    def exist?
      _persisted_node && _persisted_node.exist?
    end

    def destroy
      _persisted_node && _persisted_node.del
    end

    def update(props)
      @attributes && @attributes.merge!(props.stringify_keys)
      _persisted_node.props = persistable_attributes
    end

    def _create_node(*args)
      session = Neo4j::Session.current
      props = args[0] if args[0].is_a?(Hash)
      labels = self.class.respond_to?(:mapped_label_names) ? self.class.mapped_label_names : []
      session.create_node(props, labels)
    end

    def persistable_attributes
      (@attributes ? @attributes.merge(attributes) : attributes).reject{|k,v| v.nil?}
    end

    module ClassMethods
      def create(props = {})
        new(props).tap do |obj|
          obj.save
        end
      end
    end

  end

end