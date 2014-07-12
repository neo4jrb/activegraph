module Neo4j::ActiveNode
	module SerializedProperties
    extend ActiveSupport::Concern

    def serialized_properties
    	self.class.serialized_properties
    end

		module ClassMethods

			def serialized_properties=(name)
				@serialize ||= []
				@serialize.push name
			end

			def serialized_properties
				@serialize || []
			end

			def serialize(name)
				self.serialized_properties = name
			end
		end
	end
end