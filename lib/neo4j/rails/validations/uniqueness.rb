module Neo4j
	module Rails
		module Validations
			extend ActiveSupport::Concern
			
			class UniquenessValidator < ActiveModel::EachValidator
				def initialize(options)
					super(options.reverse_merge(:case_sensitive => true))
				end
	
				def setup(klass)
					@attributes.each do |attribute|
						if klass.index_type_for(attribute) != :exact
							raise "Can't validate property #{attribute.inspect} on class #{klass} since there is no :exact lucene index on that property or the index declaration #{attribute} comes after the validation declaration in #{klass} (try to move it before the validation rules)"
						end
					end
				end
	
				def validate_each(record, attribute, value)
					return if options[:allow_blank] && value.blank?
					record.class.all("#{attribute}: \"#{value}\"").each do |rec|
            if rec.id != record.id # it doesn't count if we find ourself!
              record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
              break
            end
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
