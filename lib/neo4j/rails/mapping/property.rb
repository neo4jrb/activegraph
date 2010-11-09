module Neo4j
	module Rails
		module Mapping
			module Property
				extend ActiveSupport::Concern
					
				def []=(key, value)
					attribute_will_change!(key.to_s) if self[key.to_s] != value
					super
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
			end
		end
	end
end
