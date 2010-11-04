module Neo4j
	module Rails
		module Mapping
			module ClassMethods
				module Property
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

						# TODO: Write the code that handles default property values
						#self[property] = options[:default] if options[:default]
						validates(property, :nil => options[:null] == false ? false : true) if options.has_key?(:null)
						validates(property, :length => { :maximum => options[:limit] }) if options[:limit]
					end
				end
			end
		end
	end
end
