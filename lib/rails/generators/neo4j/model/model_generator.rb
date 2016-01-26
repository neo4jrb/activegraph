require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'neo4j.rb')

class Neo4j::Generators::ModelGenerator < Neo4j::Generators::Base #:nodoc:
  argument :attributes, type: :array, default: [], banner: 'field:type field:type'

  check_class_collision

  class_option :timestamps, type: :boolean
  class_option :parent,     type: :string, desc: 'The parent class for the generated model'
  class_option :indices,    type: :array,  desc: 'The properties which should be indexed'
  class_option :has_one,    type: :array,  desc: 'A list of has_one relationships'
  class_option :has_many,   type: :array,  desc: 'A list of has_many relationships'

  def create_model_file
    template 'model.erb', File.join('app/models', class_path, "#{singular_name}.rb")
  end

  protected

  def migration?
    false
  end

  def timestamps?
    options[:timestamps]
  end

  # rubocop:disable Style/PredicateName
  def has_many?
    options[:has_many]
  end

  def has_many_statements
    txt = ''
    options[:has_many].each do |key|
      txt << has_x('has_many', key)
    end
    txt
  end

  def has_one?
    options[:has_one]
  end

  def has_x(method, key)
    to, from = key.split(':')
    (from ? "\n  #{method}(:#{to}).from(:#{from})\n" : "\n  #{method} :#{to}")
  end

  def has_one_statements
    txt = ''
    options[:has_one].each do |key|
      txt << has_x('has_one', key)
    end
    txt
  end
  # rubocop:enable Style/PredicateName

  def indices?
    options[:indices]
  end


  def index_fragment(property)
    return if !options[:indices] || !options[:indices].include?(property)

    "index :#{property}"
  end

  def parent?
    options[:parent]
  end

  def timestamp_statements
    '
  property :created_at, type: DateTime
  # property :created_on, type: Date

  property :updated_at, type: DateTime
  # property :updated_on, type: Date

'
  end

  hook_for :test_framework
end
