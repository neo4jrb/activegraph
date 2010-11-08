module Neo4j
	module Rails
		module Mapping
			module Property
				extend ActiveSupport::Concern
				
				def [](key)
					reverse_cast(key, super)
				end
				
				# redefine this methods so that ActiveModel::Dirty will work
				def []=(key, value)
					new_value = cast(key, value)
					key = key.to_s
					unless key[0] == ?_
						old_value = self.send(:[], key)
						attribute_will_change!(key) unless old_value == new_value
					end
					Neo4j::Rails::Transaction.running? ? super(key, new_value) : Neo4j::Rails::Transaction.run { super(key, new_value) }
				end
				
				module ClassMethods
					# Handle some additional options for the property
					#
					# Set a default - 							:default => "default"
					# Prpoerty must be there - 			:null => false
					# Property has a length limit - :limit => 128
					def property(*args)
						super
						handle_property_options_for(args.first)
					end
					
					protected
					def handle_property_options_for(property)
						options = _decl_props[property.to_sym]
		
						write_inheritable_attribute(:attribute_defaults, property => options[:default]) if options[:default]
						validates(property, :non_nil => true) if options.has_key?(:null) && options[:null] == false
						validates(property, :length => { :maximum => options[:limit] }) if options[:limit]
					end
				end
				
				protected
				# cast the value for this property into the correct type for storing in Neo4j
				def cast(key, value)
					if value.is_a?(Date)
						value.to_s
					elsif value.is_a?(Time)
						value.to_i
					else
						value
					end
				end
				
				# convert a stored value back into the appropriate Ruby type
				def reverse_cast(key, value)
					return value unless property = self.class._decl_props[key]
					
					if property[:type] == Date || property[:type] == DateTime
						property[:type].parse(value.to_s)
					elsif property[:type] == Time
						Time.at(value.to_i)
					else
						value
					end
				end
			end
		end
	end
end
