module Neo4j::ActiveRel
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Shared::Persistence

    class RelInvalidError < RuntimeError; end
    class ModelClassInvalidError < RuntimeError; end
    class RelCreateFailedError < RuntimeError; end

    def clear_association_cache; end

    def save(*)
      update_magic_properties
      create_or_update
    end

    def save!(*args)
      fail RelInvalidError, self unless save(*args)
    end

    def create_model(*)
      validate_node_classes!
      create_magic_properties
      set_timestamps
      properties = convert_properties_to :db, props
      rel = _create_rel(from_node, to_node, properties)
      return self unless rel.respond_to?(:_persisted_obj)
      init_on_load(rel._persisted_obj, from_node, to_node, @rel_type)
      true
    end

    module ClassMethods
      # Creates a new relationship between objects
      # @param [Hash] props the properties the new relationship should have
      def create(props = {})
        relationship_props = extract_association_attributes!(props) || {}
        new(props).tap do |obj|
          relationship_props.each do |prop, value|
            obj.send("#{prop}=", value)
          end
          obj.save
        end
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        fail RelInvalidError, self unless create(*args)
      end
    end

    private

    def validate_node_classes!
      [from_node, to_node].each do |node|
        type = from_node == node ? :_from_class : :_to_class
        type_class = self.class.send(type)

        next if [:any, false].include?(type_class)

        fail ModelClassInvalidError, "Node class was #{node.class}, expected #{type_class}" unless node.is_a?(type_class.to_s.constantize)
      end
    end

    def _create_rel(from_node, to_node, *args)
      props = self.class.default_property_values(self)
      props.merge!(args[0]) if args[0].is_a?(Hash)
      set_classname(props, true)

      fail RelCreateFailedError, "Unable to create relationship (id is nil). from_node: #{from_node}, to_node: #{to_node}" if from_node.id.nil? || to_node.id.nil?
      _rel_creation_query(from_node, to_node, props)
    end

    private

    def _rel_creation_query(from_node, to_node, props)
      from_class = from_node.class
      to_class = to_node.class

      Neo4j::Session.query.match(n1: {from_class.mapped_label_name => {from_class.primary_key => from_node.id}},
                                 n2: {to_class.mapped_label_name => {to_class.primary_key => to_node.id}})
        .send(create_method, "n1-[r:`#{type}`]->n2")
        .with('r').set(r: props).pluck(:r).first
    end

    def create_method
      self.class.unique? ? :create_unique : :create
    end
  end
end
