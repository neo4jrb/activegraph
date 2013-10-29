module Neo4j
	module Rails
		module Validations
			class NonNilValidator < ActiveModel::EachValidator
				def validate_each(record, attribute, value)
					record.errors.add(attribute, :nil, options.merge(:value => value)) if value.nil?
				end
			end
		end
  end
end
