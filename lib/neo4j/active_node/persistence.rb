module Neo4j::ActiveNode
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Library::Persistence

    # Creates a model with values matching those of the instance attributes and returns its id.
    # @private
    # @return true
    def create_model(*)
      create_magic_properties
      set_timestamps
      properties = convert_properties_to :db, props
      node = _create_node(properties)
      init_on_load(node, node.props)
      # Neo4j::IdentityMap.add(node, self)
      # write_changed_relationships
      true
    end

    def _create_node(*args)
      session = self.class.neo4j_session
      props = self.class.default_property_values(self)
      props.merge!(args[0]) if args[0].is_a?(Hash)
      set_classname(props)
      labels = self.class.mapped_label_names
      session.create_node(props, labels)
    end

    module ClassMethods
      # Creates a saves a new node
      # @param [Hash] props the properties the new node should have
      def create(props = {})
        relationship_props = extract_relationship_attributes!(props)

        new(props).tap do |obj|
          obj.save
          relationship_props.each do |prop, value|
            obj.send("#{prop}=", value)
          end
        end
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        props = args[0] || {}
        relationship_props = extract_relationship_attributes!(props)

        new(*args).tap do |o|
          yield o if block_given?
          o.save!
          relationship_props.each do |prop, value|
            o.send("#{prop}=", value)
          end
        end
      end

      def load_entity(id)
        Neo4j::Node.load(id)
      end
    end

    private

  end
end
