module Neo4j
	module Rails
		module Callbacks #:nodoc:
			extend ActiveSupport::Concern
			
			included do
				[:create_or_update, :create, :update, :destroy].each do |method|
					alias_method_chain method, :callbacks
				end
				
				extend ActiveModel::Callbacks
				
				define_model_callbacks :create, :save, :update, :destroy
			end
			
			def destroy_with_callbacks #:nodoc:
				_run_destroy_callbacks { destroy_without_callbacks }
			end
			
			private
			def create_or_update_with_callbacks #:nodoc:
				_run_save_callbacks { create_or_update_without_callbacks }
			end
	
			def create_with_callbacks #:nodoc:
				_run_create_callbacks { create_without_callbacks }
			end
	
			def update_with_callbacks(*) #:nodoc:
				_run_update_callbacks { update_without_callbacks }
			end
		end
	end
end
