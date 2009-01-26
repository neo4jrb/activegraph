$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib")
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/..")

require 'neo4j'
require 'neo4j/spec_helper'
require 'date'

class MyPropertyData
  attr_accessor :x
  def initialize(x)
    @x = x
  end
end


describe 'NodeMixin having no properties' do
  before(:all) do
    start
    undefine_class :MyNode
    class MyNode
      include Neo4j::NodeMixin
    end
  end


  after(:all) { stop }

  it "should have no info about any properties" do
    MyNode.properties_info.should be_empty
    MyNode.properties_info[:since].should be_nil
  end


  it "should have info about properties that are later added to the class" do
    MyNode.property :since, :type=>Date
    MyNode.properties_info.should_not be_empty
    MyNode.properties_info[:since][:type].should == Date
  end

end

describe 'NodeMixin having Date properties' do

  before(:all) do
    start
    undefine_class :MyNode

    class MyNode
      include Neo4j::NodeMixin
      property :foo
      property :since, :type => Date
      property :from,  :type => Date
    end
  end


  after(:all) { stop }

  it "should know the type of declared properties" do
    MyNode.properties_info.size.should == 3
    MyNode.properties_info[:since][:type].should == Date
    MyNode.properties_info[:from][:type].should == Date
  end


  it "should marshal default empty hash info for all properties" do
    MyNode.properties_info[:foo].should_not be_nil
    MyNode.properties_info[:foo].class.should == Hash
    MyNode.properties_info[:fooz].should be_nil
  end

  it "should marshal Date properties" do
    n = MyNode.new
    date = Date.new 2008,12,15
    n.since = date
    n.since.class.should == Date
    n.since.should == date
  end

end


describe 'Neo4j::Node with properties of unknown type' do

  before(:all) do
    start
    undefine_class :MyNode

    class MyNode
      include Neo4j::NodeMixin
      property :fooz
    end
    @node = MyNode.new
  end


  after(:all) { stop }

  it "should have no type info" do
    MyNode.properties_info.size.should == 1
    MyNode.properties_info[:fooz][:type].should be_nil
  end

  it "should raise an exeption if a property is not of type String,Boolean,Fixnum,Float,Array" do
    lambda{ @node.fooz = MyPropertyData.new(98) }.should raise_error
  end

  it "should allow to set properties of type Fixnum" do
    # when
    @node.fooz = 42
    # then
    Neo4j.load(@node.neo_node_id).fooz.should == 42
  end

  it "should allow to set properties of type Float" do
    # when
    @node.fooz = 3.1415
    # then
    Neo4j.load(@node.neo_node_id).fooz.should == 3.1415
  end


  it "should allow to set properties of type true and false" do
    @node.fooz = true
    Neo4j.load(@node.neo_node_id).fooz.should == true
    Neo4j.load(@node.neo_node_id).fooz.class.should == TrueClass
    @node.fooz = false
    Neo4j.load(@node.neo_node_id).fooz.should == false
    Neo4j.load(@node.neo_node_id).fooz.class.should == FalseClass
  end

end

describe 'Neo4j::Node having a property of type Object' do
  before(:each) do
    start
    undefine_class :Stuff
    class Stuff
      include Neo4j::NodeMixin
      property :stuff, :type => Object
      property :foo
    end

    @node = Stuff.new
  end

  after(:each) { stop }

  it "should know the type of the property" do
    Stuff.properties_info[:stuff].class.should == Hash
    Stuff.properties_info[:stuff][:type].should == Object
  end

  it "should have no type unless specified" do
    Stuff.properties_info[:foo].class.should == Hash
    Stuff.properties_info[:foo][:type].should be_nil
  end

  it "should allow to set properties of type Array" do
    # when
    array = [1,"2",3.14]
    @node.stuff = array
    
    # then
    node = Neo4j.load(@node.neo_node_id)
    node.stuff.class == Array
    node.stuff.should == array
    node.stuff.object_id.should_not == array.object_id
  end

  it "should allow to set the property to any object" do
    data = MyPropertyData.new(98)

    # when
    @node.stuff = data

    # then
    node = Neo4j.load(@node.neo_node_id)
    node.stuff.class == MyPropertyData
    node.stuff.x.should == 98
    node.stuff.object_id.should_not == data.object_id
  end

end

# ----------------------------------------------------------------------------
# property
#

describe 'Neo4j properties' do
  before(:each) do
    start
    undefine_class :TestNode  # make sure it is not already defined
    class TestNode
      include Neo4j::NodeMixin
      property :p1, :p2
    end
    @node = TestNode.new
  end

  after(:each) { stop }
  
  it "should know which properties has been set" do
    @node.p1 = "val1"
    @node.p2 = "val2"
  
    @node.props.should have_key('p1')
    @node.props.should have_key('p2')
  end

  it "should know with properties has been defined on the class" do
    TestNode.property?(:p1).should be_true
    TestNode.property?(:p2).should be_true
    TestNode.property?('p1').should be_true
    TestNode.property?('p2').should be_true

    TestNode.property?(:p3).should be_false
    TestNode.property?("ojojoj").should be_false
  end
  
  it "should allow to get a property that has not been set" do
    @node.should_not be_property('p1')
    @node.p1.should be_nil
  end


  it "should have a neo id property" do
    @node.should respond_to(:neo_node_id)
    @node.neo_node_id.should be_kind_of(Fixnum)
  end
  
  it "should have a property for the ruby class it represent" do
    @node.classname.should be == TestNode.to_s
  end
  
  it "should allow to set any property" do
    # given
    @node.p1 = "first"
  
    # when
    @node.p1 = "Changed it"
  
    # then
    @node.p1.should =='Changed it'
  end
  
  it "should allow to set properties to nil" do
    @node.p1 = nil
    @node.p1.should == nil
    @node.p1 = 42
    @node.p1 = nil
    @node.p1.should == nil
  end

  it "should allow to remove a property by setting it to nil" do
    # given
    @node.should_not be_property('p1')
    @node.p1 = 4
    @node.p1.should == 4
    @node.should be_property('p1')

    # when
    @node.p1 = nil

    # then
    @node.should_not be_property('p1')
    @node.p1.should be_nil
  end

  it "should allow to remove a property" do
    # given
    @node.should_not be_property('p1')
    @node.p1 = 4
    @node.p1.should == 4
    @node.should be_property('p1')

    # when
    @node.remove_property('p1')

    # then
    @node.should_not be_property('p1')
    @node.p1.should be_nil
  end
  
  it "should generated setter and getters methods" do
    # when
    p = TestNode.new {}
  
    # then
    p.methods.should include('p1','p2')
    p.methods.should include("p1=", 'p2=')
  end
  
  it "should automatically be defined on subclasses" do
    undefine_class :SubNode  # make sure it is not already defined
  
    # given
    class SubNode < TestNode
      property :salary
    end
  
    # when
    p = SubNode.new {}
  
    # then
    p.methods.should include("p1",'p2')
    p.methods.should include("salary", "salary=")
  end
  
  

end
