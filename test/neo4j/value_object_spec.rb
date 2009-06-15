$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'



undefine_class :FooBarNode

class FooBarNode
  include Neo4j::NodeMixin
  property :name, :age
end

describe 'ValueObjects' do

  before(:all) { start; Neo4j::Transaction.new }
  after(:all) { stop; Neo4j::Transaction.finish }


  it "should value object created with new param should be anew record" do
    clazz = FooBarNode.value_object
    a = clazz.new
    a.should be_new_record
  end

  it "update with correct values" do
    clazz = FooBarNode.value_object
    a = clazz.new
    a._update(:name => 'hej', :age=>42)
    a.name.should == 'hej'
    a.age.should == 42
    a.should_not be_new_record
  end

  it "update with incorrect values" do
    clazz = FooBarNode.value_object
    a = clazz.new
    a._update(:ojoj => 'hej', :age=>42)
    a.name.should == nil
    a.age.should == 42
    a.should_not be_new_record
  end

  it "create a value object from an existing node" do
    node = FooBarNode.new
    node.name = 'hej'

    vo = node.value_object
    vo.name.should == 'hej'
    vo.age.should be_nil
    vo.should_not be_new_record
  end

end

