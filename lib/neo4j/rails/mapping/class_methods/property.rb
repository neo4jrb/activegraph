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
						handle_property_options
					end
					
					protected
					def handle_property_options
						_decl_props.each_pair do |property, options|
							handle_options_for(property, options)
						end
					end
					
					def handle_options_for(property, options)
						# TODO: Write the code that handles default property values
						#self[property] = options[:default] if options[:default]
						validates(property, :presence => true) if options.has_key?(:null) && options[:null] == false
						validates(property, :length => { :maximum => options[:limit] }) if options[:limit]
					end
				end
			end
		end
	end
end
