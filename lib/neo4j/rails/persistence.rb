module Neo4j
	module Rails
		module Persistence
			extend ActiveSupport::Concern
			
			included do
				extend TxMethods
				tx_methods :destroy, :create, :update, :update_nested_attributes
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
			# Raises a RecordInvalidError if there is a problem duruing save.
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
				del unless new_record?
				set_deleted_properties
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
        @_deleted
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
				reset_attributes
				reload_from_database or set_deleted_properties and return self
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
			
			module ClassMethods
				# Initialize a model and set a bunch of attributes at the same time.  Returns
				# the object whether saved successfully or not.
				def create(*args)
					new(*args).tap {|o| o.save }
				end
				
				# Same as #create, but raises an error if there is a problem during save.
				# Returns the object whether saved successfully or not.
				def create!(*args)
					new(*args).tap {|o| o.save! }
				end
			end
			
			protected
			def create_or_update
				result = persisted? ? update : create
				result != false
			end
			
			def update
				write_changed_attributes
				update_timestamp
				clear_changes
				true
			end
			
			def create
				node = Neo4j::Node.new
				#unless _java_node.save_nested(node)
				#	Neo4j::Rails::Transaction.fail
				#	false
				#else
				init_on_load(node)
				init_on_create(@properties)
				clear_changes
				true
			end
			
			def init_on_create(*args)
				self["_classname"] = self.class.to_s
				write_default_attributes
				write_changed_attributes
				create_timestamp
			end
			
			def reset_attributes
				@properties = {}
			end
			
			def reload_from_database
      	if reloaded = self.class.load(id)
					send(:attributes=, reloaded.attributes, false)
				end
			end
			
      def set_deleted_properties
      	@_deleted = true
				@_persisted = false
				@_java_node = nil
			end
			
			# Ensure any defaults are stored in the DB
			def write_default_attributes
				attribute_defaults.each do |attribute, value|
					write_attribute(attribute, value) unless changed_attributes.has_key?(attribute) || _java_node.has_property?(attribute)
				end
			end
			
			# Write attributes to the Neo4j DB only if they're altered
			def write_changed_attributes
				@properties.each do |attribute, value|
					write_attribute(attribute, value) if changed_attributes.has_key?(attribute)
				end
			end
			
			# Set the timestamps for this model if timestamps is set to true in the config
			# and the model is set up with the correct property name, e.g.:
			#
			#   class Trackable < Neo4j::Rails::Model
			#     property :updated_at, :type => DateTime
			#   end
			def update_timestamp
				write_date_or_timestamp(:updated_at) if Neo4j::Config[:timestamps] && respond_to?(:updated_at)
			end
			
			# Set the timestamps for this model if timestamps is set to true in the config
			# and the model is set up with the correct property name, e.g.:
			#
			#   class Trackable < Neo4j::Rails::Model
			#     property :created_at, :type => DateTime
			#   end
			def create_timestamp
				write_date_or_timestamp(:created_at) if Neo4j::Config[:timestamps] && respond_to?(:created_at)
			end
			
			# Write the timestamp as a Date, DateTime or Time depending on the property type
			def write_date_or_timestamp(attribute)
				value = case self.class._decl_props[attribute][:type]
				when Time
					Time.now
				when Date
					Date.today
				else
					DateTime.now
				end
				
				write_attribute(attribute, value)
			end
			
			def update_nested_attributes(rel_type, clazz, has_one, attr, options)
        allow_destroy, reject_if = [options[:allow_destroy], options[:reject_if]] if options

        if new?
          # We are updating a node that was created with the 'new' method.
          # The relationship will only be kept in the Value object.
          outgoing(rel_type) << clazz.new(attr) unless reject_if?(reject_if, attr) || (allow_destroy && attr[:_destroy] && attr[:_destroy] != '0')
        else
          # We have a node that was created with the #create method - has real Neo4j relationships
          # does it exist ?
          found = if has_one
            # id == nil that means we have a has_one relationship
                    outgoing(rel_type).first
                  else
                    # do we have an ID ?
                    id = attr[:id]
                    # this is a has_n relationship, find which one we want to update
                    id && outgoing(rel_type).find { |n| n.id == id }
                  end

          # Check if we want to destroy not found nodes (e.g. {..., :_destroy => '1' } ?
          destroy = attr[:_destroy] && attr[:_destroy] != '0'

          if found
            if destroy
              found.destroy if allow_destroy
            else
              found.update_attributes_in_tx(attr) # it already exist, so update that one
            end
          elsif !destroy && !reject_if?(reject_if, attr)
            new_node = clazz.new(attr)
            saved = new_node.save
            outgoing(rel_type) << new_node if saved
          end
        end
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

