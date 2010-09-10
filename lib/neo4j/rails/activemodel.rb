
class Neo4j::ActiveModel
  include Neo4j::NodeMixin
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Dirty

  class RecordInvalidError < RuntimeError
    attr_reader :record

    def initialize(record)
      @record = record
      super(@record.errors.full_messages.join(", "))
    end
  end

  def init_on_create(props) # :nodoc:
    @_java_node = Neo4j::Node.new(props)
    puts "init on create #{self.class.name}"
    @_new_record = true
    self[:_classname] = self.class.name
  end

  # --------------------------------------
  #
  # --------------------------------------

 # def id
 #   self.neo_id
 # end

  def method_missing(method_id, *args, &block)
    if !self.class.attribute_methods_generated?
      puts "DEFINED #{self.class.properties_info.keys}"
      #self.class.define_attribute_methods([:name, :age])
      self.class.define_attribute_methods(self.class.properties_info.keys)
      # try again
      send(method_id, *args, &block)
    end
  end

  # redefine this methods so that ActiveModel::Dirty will work
  def []=(key, new_value)
    key = key.to_s
    unless key[0] == ?_
      old_value = self.send(:[], key)
      attribute_will_change!(key) unless old_value == new_value
    end
    super
  end

  # Handle Model.find(params[:id])
  def self.find(*args)
    if args.length == 1 && String === args[0] && args[0].to_i != 0
      load(*args)
    else
      super
    end
  end

  def self.load(*ids)
    result = ids.map { |id| Neo4j::Node.load(id) }
    if ids.length == 1
      result.first
    else
      result
    end
  end


  def delete
    super
    @_deleted = true
  end

  def save
    @previously_changed = changes
    @changed_attributes.clear
    if valid?
      # if we are trying to save a value then we should create a real node
      @_java_node = Neo4j::Node.new(props) unless persisted?
      true
    end
  end

  # In neo4j all object are automatically persisted in the database when created (but the Transaction might get rollback)
  # Only the Neo4j::Value object will never exist in the database
  def persisted?
    !_java_node.kind_of?(Neo4j::Value)
  end

  def save!
    raise RecordInvalidError.new(self) unless save
  end

  def to_model
    self
  end

  def new_record?()
    @_new_record
  end

  def destroyed?()
    @_deleted
  end


  # --------------------------------------
  # Class Methods
  # --------------------------------------

  class << self

    # Handle Model.find(params[:id])
    def find(*args)
      if args.length == 1 && String === args[0] && args[0].to_i != 0
        load(*args)
      else
        super
      end
    end

    def load(*ids)
      result = ids.map { |id| Neo4j::Node.load(id) }
      if ids.length == 1
        result.first
      else
        result
      end
    end

    # Returns a value object,
    # This is a bit the same as the ActiveRecord#new method which does not create the node
    #
    def value(*args)
      value = Neo4j::Value.new(*args)
      obj = self.new(value)
      obj.init_node(*args) if obj.respond_to?(:init_node)
      obj
    end
  end

end


#class LintTest < ActiveModel::TestCase
#  include ActiveModel::Lint::Tests
#
#  class MyModel
#    include Neo4j::NodeMixin
#  end
#
#  def setup
#    @model = MyModel.new
#  end
#
#end
#
#require 'test/unit/ui/console/testrunner'
#Neo4j::Transaction.run do
#  Test::Unit::UI::Console::TestRunner.run(LintTest)
#end
