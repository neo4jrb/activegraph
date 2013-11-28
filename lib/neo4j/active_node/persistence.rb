module Neo4j::ActiveNode
  module Persistence
    extend ActiveSupport::Concern

    def save
      node = _create_node(props)
      init_on_load(node, node.props)
    end

    def neo_id
      _persisted_node.neo_id if _persisted_node
    end

    alias :id :neo_id

    def exist?
      _persisted_node && _persisted_node.exist?
    end

    # Returns +true+ if the object was destroyed.
    def destroyed?
      @_deleted || (!new_record? && !exist?)
    end

    # Returns +true+ if the record is persisted, i.e. it’s not a new record and it was not destroyed
    def persisted?
      !new_record? && !destroyed?
    end

    # Returns +true+ if the record hasn't been saved to Neo4j yet.
    def new_record?
      ! _persisted_node
    end

    alias :new? :new_record?

    def destroy
      _persisted_node && _persisted_node.del
      @_deleted = true
    end

    def update(props)
      @attributes && @attributes.merge!(props.stringify_keys)
      _persisted_node.props = props
    end

    def _create_node(*args)
      session = Neo4j::Session.current
      props = args[0] if args[0].is_a?(Hash)
      labels = self.class.respond_to?(:mapped_label_names) ? self.class.mapped_label_names : []
      session.create_node(props, labels)
    end

    def props
      (@attributes ? @attributes.merge(attributes) : attributes).reject{|k,v| v.nil?}.symbolize_keys
    end

    module ClassMethods
      def create(props = {})
        new(props).tap do |obj|
          obj.save
        end
      end

      def load_entity(id)
        instance = Neo4j::Node.load(id)
        raise "Illegal class loaded" unless instance.kind_of?(self)
        instance
      end
    end

  end

end