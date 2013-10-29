module Neo4j
	module Rails
		module Serialization
			extend ActiveSupport::Concern
			
			included do
				include ActiveModel::Serializers::Xml
        include ActiveModel::Serializers::JSON
				# Patch for ActiveModel's XML serializer.  There is a bug in the original where
				# raw_value is used in the initializer and so demands always that the object being 
				# serialized is sent the attribute's name as a method call.  This causes a problem
				# for Neo4j properties that aren't declared and so don't have methods to call.  Besides
				# which it's not necessary to re-call to get the value again if it has already
				# been passed.
				class ActiveModel::Serializers::Xml::Serializer::Attribute
					def initialize(name, serializable, raw_value=nil)
            @name, @serializable = name, serializable
            @value = raw_value || @serializable.send(name)
            @type  = compute_type
          end
        end
			end
		end
	end
end
