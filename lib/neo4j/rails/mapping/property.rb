module Neo4j
	module Rails
		module Mapping
			module Property
				extend ActiveSupport::Concern
					
				module ClassMethods
					# Handles options for the property
					#
					# Set the property type 				:type => Time
					# Set a default  								:default => "default"
					# Property must be there  			:null => false
					# Property has a length limit  	:limit => 128
					def property(*args)
						options = args.extract_options!
						args.each do |property_sym|
							property_setup(property_sym, options)
						end
					end
					
					protected
					def property_setup(property, options)
						_decl_props[property] = options
						handle_property_options_for(property, options)
						define_property_methods_for(property, options)
						_decl_props[property][:defined] = true
					end
					
					def handle_property_options_for(property, options)
						attribute_defaults[property.to_s] = options[:default] if options.has_key?(:default)
            if options.has_key?(:null) && options[:null] === false
              validates(property, :non_nil => true, :on => :create)
              validates(property, :non_nil => true, :on => :update)
            end
						validates(property, :length => { :maximum => options[:limit] }) if options[:limit]
					end
					
					def define_property_methods_for(property, options)
						unless method_defined?(property)
							class_eval <<-RUBY, __FILE__, __LINE__
								def #{property}
									send(:[], "#{property}")
								end
							RUBY
						end
						
						unless method_defined?("#{property}=".to_sym)
							class_eval <<-RUBY, __FILE__, __LINE__
								def #{property}=(value)
									send(:[]=, "#{property}", value)
								end
							RUBY
						end
					end
				end
			end
		end
	end
end
