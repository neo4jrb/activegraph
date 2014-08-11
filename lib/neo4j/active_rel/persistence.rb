module Neo4j::ActiveRel
  module Persistence
    extend ActiveSupport::Concern
    include Neo4j::Library::Persistence

    class RelInvalidError < RuntimeError
      attr_reader :record

      def initialize(record)
        @record = record
        super(@record.errors.full_messages.join(", "))
      end
    end

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
      create_magic_properties
      set_timestamps
      properties = convert_properties_to :db, props
      rel = _create_rel(properties)
      init_on_load(rel, inbound, outbound, @rel_type)
      true
    end

    module ClassMethods

      # Creates a new relationship between objects
      # @param [Hash] props the properties the new relationship should have
      def create(props = {})
        relationship_props = extract_relationship_attributes!(props) || {}
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

    def _create_rel(*args)
      session = self.class.neo4j_session
      props = self.class.default_property_values(self)
      props.merge!(args[0]) if args[0].is_a?(Hash)
      set_classname(props)
      outbound.create_rel(rel_type, inbound, props)
    end
  end
end
