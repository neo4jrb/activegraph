module Neo4j
	module Rails
		module Callbacks #:nodoc:
			extend ActiveSupport::Concern

      CALLBACKS = [
        :before_validation, :after_validation,
        :before_create, :around_create, :after_create,
        :before_destroy, :around_destroy, :after_destroy,
        :before_save, :around_save, :after_save,
        :before_update, :around_update, :after_update,
        ].freeze

			included do
				[:valid?, :create_or_update, :create, :update, :destroy].each do |method|
					alias_method_chain method, :callbacks
				end
				
				extend ActiveModel::Callbacks
				
				define_model_callbacks :validation, :create, :save, :update, :destroy
			end
			
			def valid_with_callbacks?(*) #:nodoc:
			  _run_validation_callbacks { valid_without_callbacks? }
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
