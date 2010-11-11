module Neo4j
	module Rails
		module Persistence
			extend ActiveSupport::Concern
			
			included do
				extend TxMethods
				tx_methods :destroy, :create, :update, :update_attributes, :update_attributes!, :update_nested_attributes
			end

			class RecordInvalidError < RuntimeError
        attr_reader :record

        def initialize(record)
          @record = record
          super(@record.errors.full_messages.join(", "))
        end
      end
      
      def init_on_create(*args) # :nodoc:
        super()
        self.attributes=args[0] if args[0].respond_to?(:each_pair)
      end
      
      def save(*)
      	create_or_update
      end
      
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
				send("#{name}=", value)
				save(:validate => false)
			end
			
			def destroy
				del
				set_deleted_properties
			end
			
			def destroyed?()
        @_deleted
      end
			
			# Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
      # If saving fails because the resource is invalid then false will be returned.
      def update_attributes(attributes)
        self.attributes=attributes
        save
      end

      def update_attributes!(attributes)
        self.attributes=attributes
        save!
      end
			
			def reload(options = nil)
				clear_changes
				reload_from_database or set_deleted_properties and return self
      end
      
      # Returns if the record is persisted, i.e. it’s not a new record and it was not destroyed
      def persisted?
        !new_record? && !destroyed?
      end
      
      def new?
        _java_node.kind_of?(Neo4j::Rails::Value)
      end
      
      alias :new_record? :new?
			
			module ClassMethods
				def create(*args)
					new(*args).tap {|o| o.save }
				end
				
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
				clear_changes
				self.updated_at = DateTime.now if Neo4j::Config[:timestamps] && respond_to?(:updated_at)
				true
			end
			
			def create
				node = Neo4j::Node.new(props)
				unless _java_node.save_nested(node)
					Neo4j::Rails::Transaction.fail
					false
				else
					init_on_load(node)
					init_on_create
					self.created_at = DateTime.now if Neo4j::Config[:timestamps] && respond_to?(:created_at)
					clear_changes
					true
				end
			end
			
			def reload_from_database
      	if reloaded = self.class.load(self.id.to_s)
					attributes = reloaded.attributes
				end
			end
			
      def set_deleted_properties
      	@_deleted = true
				@_persisted = false
				@_java_node = Neo4j::Rails::Value.new(self)
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
		end
	end
end

