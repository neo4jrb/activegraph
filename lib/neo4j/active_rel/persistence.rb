module Neo4j::ActiveRel
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Library::Persistence

    def save(*)
      if inbound.nil? || outbound.nil?
        return false
      end
      update_magic_properties
      create_or_update
    end

    def save!(*)
      #raise RecordInvalidError.new(self) unless save(*)
    end

    def create_model(*)
      create_magic_properties
      set_timestamps
      properties = convert_properties_to :db, props
      rel = _create_rel(properties)
      init_on_load(rel, inbound, outbound, @rel_type)
      true
    end

    def _create_rel(*args)
      session = self.class.neo4j_session
      props = self.class.default_property_values(self)
      props.merge!(args[0]) if args[0].is_a?(Hash)
      set_classname(props)
      outbound.create_rel(rel_type, inbound, props)
    end

    module ClassMethods

      # Creates a new relationship between objects
      # @param [Hash] props the properties the new relationship should have
      def create(outbound, inbound, props = {})
        return false unless outbound.is_a?(outbound_class) && inbound.is_a?(inbound_class)
        outbound.create_rel(@rel_type, inbound, props)
      end

      # Same as #create, but raises an error if there is a problem during save.
      def create!(*args)
        return false unless outbound.is_a?(outbound_class) && inbound.is_a?(inbound_class)
        raise RecordInvalidError.new(self) unless outbound.create_rel(@rel_type, inbound, props)
      end
    end
  end
end