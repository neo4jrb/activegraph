class Neo4j::ActiveModel
  include Neo4j::NodeMixin
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Dirty


  def method_missing(method_id, *args, &block)
    if !self.class.attribute_methods_generated?
      self.class.define_attribute_methods([:name, :age])
      send(method_id, *args, &block)
    end
  end

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

  def init_on_load(*)
    # :nodoc:
    super
  end

  def delete
    super
    @_deleted = true
  end

  # this method is only called internally just before the transaction is finished
  def save
    @previously_changed = changes
    @changed_attributes.clear
  end

  # Creates a new node and initialize with given properties.
  #
  def init_on_create(*)
    # :nodoc:
    super
    @_new_record = true
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
