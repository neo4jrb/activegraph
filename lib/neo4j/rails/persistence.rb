module Neo4j
  module Rails
    module Persistence
      extend ActiveSupport::Concern

      included do
        extend TxMethods
        tx_methods :destroy, :create, :update, :update_nested_attributes, :delete, :update_attributes, :update_attributes!
      end

      # Persist the object to the database.  Validations and Callbacks are included
      # by default but validation can be disabled by passing :validate => false
      # to #save.
      def save(*)
        create_or_update
      end

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

      # Updates a single attribute and saves the record.
      # This is especially useful for boolean flags on existing records. Also note that
      #
      # * Validation is skipped.
      # * Callbacks are invoked.
      # * Updates all the attributes that are dirty in this object.
      #
      def update_attribute(name, value)
        respond_to?("#{name}=") ? send("#{name}=", value) : self[name] = value
        save(:validate => false)
      end

      # Removes the node from Neo4j and freezes the object.
      def destroy
        delete
        freeze
      end

      # Same as #destroy but doesn't run destroy callbacks and doesn't freeze
      # the object
      def delete
        del unless new_record?
        set_deleted_properties
      end

      # Returns true if the object was destroyed.
      def destroyed?()
        @_deleted || Neo4j::Node._load(id).nil?
      end

      # Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
      # If saving fails because the resource is invalid then false will be returned.
      def update_attributes(attributes)
        self.attributes = attributes
        save
      end

      # Same as #update_attributes, but raises an exception if saving fails.
      def update_attributes!(attributes)
        self.attributes = attributes
        save!
      end

      # Reload the object from the DB.
      def reload(options = nil)
        clear_changes
        clear_relationships
        clear_composition_cache
        reset_attributes
        unless reload_from_database
          set_deleted_properties
          freeze
        end
        self
      end

      # Returns if the record is persisted, i.e. it’s not a new record and it was not destroyed
      def persisted?
        !new_record? && !destroyed?
      end

      # Returns true if the record hasn't been saved to Neo4j yet.
      def new_record?
        _java_node.nil?
      end

      alias :new? :new_record?

      # Freeze the properties hash.
      def freeze
        @properties.freeze; self
      end

      # Returns +true+ if the properties hash has been frozen.
      def frozen?
        reload
        @properties.frozen?
      end

      module ClassMethods
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

      def update
        write_changed_attributes
        write_changed_relationships
        clear_changes
        clear_relationships
        true
      end

      def create
        node = Neo4j::Node.new
        @_java_node = node
        Neo4j::IdentityMap.add(node, self)
        init_on_create
        clear_changes
        clear_relationships
        true
      end

      def init_on_create(*)
        self._classname = self.class.to_s
        write_default_attributes
        write_changed_attributes
        write_changed_relationships
      end

      def reset_attributes
        @properties = {}
      end

      def reload_from_database
        Neo4j::IdentityMap.remove_node_by_id(id)
        if reloaded = self.class.load(id)
          clear_relationships
          send(:attributes=, reloaded.attributes, false)
        end
        reloaded
      end

      def set_deleted_properties
        @_deleted   = true
        @_persisted = false
        @_java_node = nil
      end

      # Ensure any defaults are stored in the DB
      def write_default_attributes
        attribute_defaults.each do |attribute, value|
          write_attribute(attribute, Neo4j::TypeConverters.convert(value, attribute, self.class, false)) unless changed_attributes.has_key?(attribute) || _java_node.has_property?(attribute)
        end
      end

      # Write attributes to the Neo4j DB only if they're altered
      def write_changed_attributes
        @properties.each do |attribute, value|
          write_attribute(attribute, value) if changed_attributes.has_key?(attribute)
        end
      end

      def _create_entity(rel_type, attr)
        clazz = self.class._decl_rels[rel_type.to_sym].target_class
        _add_relationship(rel_type, clazz.new(attr))
      end

      def _add_relationship(rel_type, node)
        if respond_to?("#{rel_type}_rel")
          send("#{rel_type}=", node)
        elsif respond_to?("#{rel_type}_rels")
          has_n = send("#{rel_type}")
          has_n << node
        else
          raise "oops #{rel_type}"
        end
      end

      def _find_node(rel_type, id)
        return nil if id.nil?
        if respond_to?("#{rel_type}_rel")
          send("#{rel_type}")
        elsif respond_to?("#{rel_type}_rels")
          has_n = send("#{rel_type}")
          has_n.find { |n| n.id == id }
        else
          raise "oops #{rel_type}"
        end
      end

      def _has_relationship(rel_type, id)
        !_find_node(rel_type,id).nil?
      end

      def update_nested_attributes(rel_type, attr, options)
        allow_destroy, reject_if = [options[:allow_destroy], options[:reject_if]] if options
        begin
          # Check if we want to destroy not found nodes (e.g. {..., :_destroy => '1' } ?
          destroy = attr.delete(:_destroy)
          found = _find_node(rel_type, attr[:id]) || Model.find(attr[:id])
          if allow_destroy && destroy && destroy != '0'
            found.destroy if found
          else
            if not found
              _create_entity(rel_type, attr) #Create new node from scratch
            else
              #Create relationship to existing node in case it doesn't exist already
              _add_relationship(rel_type, found) if (not _has_relationship(rel_type,attr[:id]))
              found.update_attributes(attr)
            end
          end
        end unless reject_if?(reject_if, attr)
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

