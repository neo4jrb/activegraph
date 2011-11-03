require File.join(File.dirname(__FILE__), '..', '..', 'neo4j.rb')

class Neo4j::Generators::ModelGenerator < Neo4j::Generators::Base #:nodoc:
	argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
	
	check_class_collision
	
	class_option :timestamps, :type => :boolean
	class_option :parent,     :type => :string, :desc => "The parent class for the generated model"
  class_option :indices,    :type => :array,  :desc => "The properties which should be indexed"
  class_option :has_one,    :type => :array,  :desc => "A list of has_one relationships"
  class_option :has_n,      :type => :array,  :desc => "A list of has_n relationships"

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

  def has_n?
    options[:has_n]
  end

  def has_n_statements
    txt = ""
    options[:has_n].each do |key|
      to, from = key.split(':')
      txt << (from ? "\n  has_n(:#{to}).from(:#{from})\n" : "\n  has_n :#{to}")
    end
    txt
  end

  def has_one?
    options[:has_one]
  end

  def has_one_statements
    txt = ""
    options[:has_one].each do |key|
      to, from = key.split(':')
      txt << (from ? "\n  has_one(:#{to}).from(:#{from})\n" : "\n  has_one :#{to}")
    end
    txt
  end

  def indices?
    options[:indices]
  end

  def indices_statements
    puts "indices_statements #{options[:indices].inspect}"
    txt = ""
    options[:indices].each do |key|
      txt << %Q{
  index :#{key}}
    end
    txt
  end

	def parent?
		options[:parent]
	end
	
	def timestamp_statements
		%q{
  property :created_at, :type => DateTime
  # property :created_on, :type => Date

  property :updated_at, :type => DateTime
  # property :updated_on, :type => Date
}            
	end
	
	hook_for :test_framework
end
