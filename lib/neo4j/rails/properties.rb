module Neo4j
	module Rails
    # provide some properties before we have a real node or relationship
		module Properties # :nodoc:
			include Neo4j::Property
			
			# override Neo4j::Property#props
			def props
				@props ||= {}
			end
			
			def has_property?(key)
				!props[key].nil?
			end
			
			def set_property(key,value)
				props[key] = value
			end
	
			def get_property(key)
				props[key]
			end
	
			def remove_property(key)
				props.delete(key)
			end
		end
	end
end
