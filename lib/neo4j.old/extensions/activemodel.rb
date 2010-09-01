require 'rubygems'
require 'singleton'
require 'neo4j'
require 'active_model'


module Neo4j::NodeMixin
  def to_model
    Neo4j::ActiveModel::ActiveModelFactory.instance.to_model(self)
  end

  def attributes
    attr = props
    attr.keys.each {|k| attr.delete k if k[0] == ?_}
    attr
  end

end

module Neo4j::ActiveModel

  def self.on_property_changed(node, key, old_value, new_value)
    # make model dirty since it is changed
    ActiveModelFactory.instance.dirty_node!(node.neo_id)
  end

  def self.on_tx_finished(tx)
    # make all models clean again
    ActiveModelFactory.instance.clean!
  end

  class ActiveModelFactory
    private
    def initialize
      @classes = {}
      @node_models = {}
      Thread.current[:neo4j_active_model_factory] = self
      Neo4j.event_handler.add(self)
    end

    public
    def self.instance
      # create one Neo4jActiveModelFactory for each thread
      # since a transaction belongs to a thread and we don't want
      # side effect of one transaction making model object dirty or clean for a different transaction
      # in a different thread.
      Thread.current[:neo4j_active_model_factory] || ActiveModelFactory.new
    end

    def dirty_node!(neo_id)
      @node_models[neo_id] && @node_models[neo_id].dirty!
    end

    def clean!
      @node_models.clear
    end

    def to_model(obj)
      @node_models[obj.neo_id] || create_model_for(obj)
    end

    def create_model_for(obj)
      clazz = @classes[obj.class] || create_wrapped_class_for(obj)
      @node_models[obj.neo_id] = clazz.new(obj)
    end

    def create_wrapped_class_for(obj)
      clazz = Class.new do
        def initialize(wrapped)
          @dirty = false
          @wrapped = wrapped
        end

        def dirty!
          @dirty = true
        end

        def persisted?
          ! @dirty
        end

        def to_key
          persisted? ? @wrapped.neo_id : nil
        end

        def to_param
          to_key
        end

        if obj.respond_to?(:errors)
          def errors;
            @wrapped.errors;
          end
        else
          def errors
            object = Object.new

            def object.[](key)
              []
            end

            def object.full_messages()
              []
            end

            object
          end
        end

        if obj.respond_to?(:valid?)
          def valid?;
            @wrapped.valid?;
          end
        else
          def valid?
            true
          end
        end
      end

      singleton = class << clazz;
        self;
      end
      singleton.class_eval do
        # class methods
        define_method :model_name do
          @_model_name ||= ActiveModel::Name.new(obj.class)
        end
      end

      @classes[obj.class] = clazz
      clazz
    end

  end

  Neo4j.event_handler.add(self)
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
