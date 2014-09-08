module Neo4j::ActiveRel
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Shared::Persistence

    class RelInvalidError < RuntimeError; end

    class ModelClassInvalidError < RuntimeError; end

    def save(*)
      update_magic_properties
      create_or_update
    end

    def save!(*args)
      unless save(*args)
        raise RelInvalidError.new(self)
      end
    end

    def create_model(*)
      confirm_node_classes
      create_magic_properties
      set_timestamps
      properties = convert_properties_to :db, props
      rel = _create_rel(from_node, to_node, properties)
      init_on_load(rel, to_node, from_node, @rel_type)
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
        unless create(*args)
          raise RelInvalidError.new(self)
        end
      end
    end

    private 

    def confirm_node_classes
      [from_node, to_node].each do |node|
        type = from_node == node ? :_from_class : :_to_class
        next if allows_any_class?(type)
        unless class_as_constant(type) == node.class
          raise ModelClassInvalidError, "Node class was #{node.class}, expected #{self.class.send(type)}"
        end
      end
    end

    def _create_rel(from_node, to_node, *args)
      props = self.class.default_property_values(self)
      props.merge!(args[0]) if args[0].is_a?(Hash)
      set_classname(props)
      from_node.create_rel(type, to_node, props)
    end

    def class_as_constant(type)
      given_class = self.class.send(type)
      case
      when given_class.is_a?(String)
        given_class.constantize
      when given_class.is_a?(Symbol)
        given_class.to_s.constantize
      else
        given_class
      end
    end

    def allows_any_class?(type)
      self.class.send(type) == :any || self.class.send(type) == false
    end
  end
end