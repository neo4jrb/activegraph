module Neo4j::ActiveNode
  module Persistence
    class RecordInvalidError < RuntimeError
      attr_reader :record

      def initialize(record)
        @record = record
        super(@record.errors.full_messages.join(", "))
      end
    end

    extend ActiveSupport::Concern

    def save
      create_or_update
      # TODO
      #node = _create_node(props)
      #init_on_load(node, node.props)
    end

    def create
      node = _create_node(props)
      init_on_load(node, node.props)
      # Neo4j::IdentityMap.add(node, self)
      # write_changed_relationships
      true
    end


    def update
      raise "not implemented"
    end

    # Persist the object to the database.  Validations and Callbacks are included
    # by default but validation can be disabled by passing :validate => false
    # to #save!  Creates a new transaction.
    #
    # @raise a RecordInvalidError if there is a problem during save.
    # @param (see Neo4j::Rails::Validations#save)
    # @return nil
    # @see #save
    # @see Neo4j::Rails::Validations Neo4j::Rails::Validations - for the :validate parameter
    # @see Neo4j::Rails::Callbacks Neo4j::Rails::Callbacks - for callbacks
    def save!(*args)
      unless save(*args)
        raise RecordInvalidError.new(self)
      end
    end

    def create_or_update
      # since the same model can be created or updated twice from a relationship we have to have this guard
      @_create_or_updating = true
      result = persisted? ? update : create
      unless result != false
        Neo4j::Rails::Transaction.fail if Neo4j::Rails::Transaction.running?
        false
      else
        true
      end
    rescue => e
      Neo4j::Rails::Transaction.fail if Neo4j::Rails::Transaction.running?
      raise e
    ensure
      @_create_or_updating = nil
    end

    def neo_id
      _persisted_node.neo_id if _persisted_node
    end

    def id
      neo_id.to_s
    end

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