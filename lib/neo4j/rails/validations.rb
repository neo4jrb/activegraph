module Neo4j
	module Rails
		module Validations
			include ActiveModel::Validations
			
			def read_attribute_for_validation(key)
				send(key)
			end
			
			# The validation process on save can be skipped by passing false. The regular Model#save method is
			# replaced with this when the validations module is mixed in, which it is by default.
			def save(options={})
				perform_validations(options) ? super : false
			end
	
			# Attempts to save the record just like Model#save but will raise a RecordInvalid exception instead of returning false
			# if the record is not valid.
			def save!(options={})
				perform_validations(options) ? super : raise(RecordInvalid.new(self))
			end
			
			def valid?(context = nil)
				context ||= (new_record? ? :create : :update)
				output = super(context)
	
				errors.empty? && output
    	end
			
			private
			def perform_validations(options={})
				perform_validation = case options
				when Hash
					options[:validate] != false
				end
	
				if perform_validation
					valid?(options.is_a?(Hash) ? options[:context] : nil)
				else
					true
				end
			end
		end
	end
end
