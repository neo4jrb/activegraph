module Neo4j
	module Rails
		module Validations
			class UniquenessValidator < ActiveModel::EachValidator
				def initialize(options)
					super(options.reverse_merge(:case_sensitive => true))
				end
	
				def setup(klass)
					@attributes.each do |attribute|
						if klass.index_type_for(attribute) != :exact
							raise "Can't validate property #{attribute} on class #{klass} since there is no :exact lucene index on that property or the index declaration #{attribute} comes after the validation declaration in #{klass} (try to move it before the validation rules)"
						end
					end
				end
	
				def validate_each(record, attribute, value)
					if record.class.find("#{attribute}: \"#{value}\"")
						record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
					end
				end
			end
	
			module ClassMethods
				def validates_uniqueness_of(*attr_names)
					validates_with UniquenessValidator, _merge_attributes(attr_names)
				end
			end
		end
	end
end
