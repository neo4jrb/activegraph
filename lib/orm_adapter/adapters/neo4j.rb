require 'orm_adapter'

module Neo4j
	module Rails
		class Model
			extend ::OrmAdapter::ToAdapter
  
			class OrmAdapter < ::OrmAdapter::Base
				NEO4J_REF_NODE_ID = 0
				
				# Do not consider these to be part of the class list
				def self.except_classes
					@@except_classes ||= []
				end
		
				# Gets a list of the available models for this adapter
				def self.model_classes
					::Neo4j::Rails::Model.descendants.to_a.select{|k| !except_classes.include?(k.name)}
				end
		
				# get a list of column names for a given class
				def column_names
					klass.props.keys
				end
		
				# Get an instance by id of the model
				def get!(id)
					get(id) || raise("Node not found")
				end
		
				# Get an instance by id of the model
				def get(id)
					id = wrap_key(id)
					return nil if id.to_i == NEO4J_REF_NODE_ID # getting the ref_node in this way is not supported
					klass.load(id)
				end
		
				# Find the first instance matching conditions
				def find_first(conditions)
					klass.first(conditions)
				end
		
				# Find all models matching conditions
				def find_all(conditions)
					klass.all(conditions)
				end
			
				# Create a model using attributes
				def create!(attributes)
					klass.create(attributes)
				end
			end
		end
  end
end
