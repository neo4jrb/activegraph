require File.join(File.dirname(__FILE__), '..', '..', 'neo4j.rb')

class Neo4j::Generators::ModelGenerator < Neo4j::Generators::Base #:nodoc:
	argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
	
	check_class_collision
	
	class_option :timestamps, :type => :boolean
	class_option :parent,     :type => :string, :desc => "The parent class for the generated model"
	
	def create_model_file
		template "model.erb", File.join('app/models', "#{singular_name}.rb")
	end
	
	protected
	def migration?
		false
	end
	
	def timestamps?
		options[:timestamps]
	end
	
	def parent?
		options[:parent]
	end
	
	def timestamp_statements
		%q{
  property :created_at, DateTime
  # property :created_on, Date

  property :updated_at, DateTime
  # property :updated_on, Date
}            
	end
	
	hook_for :test_framework
end
