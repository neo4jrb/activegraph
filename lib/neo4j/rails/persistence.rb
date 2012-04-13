module Neo4j
  module Rails
    module Persistence
      extend ActiveSupport::Concern
      extend TxMethods


      # Persist the object to the database.  Validations and Callbacks are included
      # by default but validation can be disabled by passing :validate => false
      # to #save.
      def save(*)
        create_or_update
      end
      tx_methods :save

      # Persist the object to the database.  Validations and Callbacks are included
      # by default but validation can be disabled by passing :validate => false
      # to #save!.
      #
      # Raises a RecordInvalidError if there is a problem during save.
      def save!(*args)
        unless save(*args)
          raise RecordInvalidError.new(self)
        end
      end

      def update
        write_changed_attributes
        clear_changes
        true
      end



      # Removes the node from Neo4j and freezes the object.
      def destroy
        delete
        freeze
      end

      # Same as #destroy but doesn't run destroy callbacks and doesn't freeze
      # the object
      def delete
        del unless new_record? || destroyed?
        set_deleted_properties
      end
      tx_methods :delete

      # Returns true if the object was destroyed.
      def destroyed?
        @_deleted || (!new_record? && !self.class.load_entity(neo_id))
      end

      # Returns if the record is persisted, i.e. it’s not a new record and it was not destroyed
      def persisted?
        !new_record? && !destroyed?
      end

      # Returns true if the record hasn't been saved to Neo4j yet.
      def new_record?
        _java_entity.nil?
      end

      alias :new? :new_record?

      # Freeze the properties hash.
      def freeze
        @_properties.freeze
        self
      end

      # Returns +true+ if the properties hash has been frozen.
      def frozen?
        reload unless new_record?
        @_properties.frozen?
      end


      module ClassMethods

        def transaction(&block)
          Neo4j::Rails::Transaction.run do |tx|
            block.call(tx)
          end
        end

        def new(*args, &block)
          instance = orig_new(*args, &block)
          instance.instance_eval(&block) if block
          instance
        end

        # Initialize a model and set a bunch of attributes at the same time.  Returns
        # the object whether saved successfully or not.
        def create(*args)
          new(*args).tap do |o|
            yield o if block_given?
            o.save
          end
        end

        # Same as #create, but raises an error if there is a problem during save.
        # Returns the object whether saved successfully or not.
        def create!(*args)
          new(*args).tap do |o|
            yield o if block_given?
            o.save!
          end
        end

        # Destroy each node in turn.  Runs the destroy callbacks for each node.
        def destroy_all
          all.each do |n|
            n.destroy
          end
        end
      end

      protected
      def create_or_update
        result = persisted? ? update : create
        unless result != false
          Neo4j::Rails::Transaction.fail if Neo4j::Rails::Transaction.running?
          false
        else
          true
        end
      end

      def set_deleted_properties
        @_deleted = true
      end

      public
      class RecordInvalidError < RuntimeError
        attr_reader :record

        def initialize(record)
          @record = record
          super(@record.errors.full_messages.join(", "))
        end
      end
    end
  end
end

