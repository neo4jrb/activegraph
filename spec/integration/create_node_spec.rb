require 'spec_helper'

describe "Neo4j::Wrapper::Labels and Neo4j::Wrapper::Initialize" do

  class MyThing
    include Neo4j::ActiveNode
    property :a
    property :x
  end


  before do
    @session = double("Mock Session")
    Neo4j::Session.stub(:current).and_return(@session)
  end

  describe 'persistable_attributes' do
    it 'does not store nil properties' do
      MyThing.new(a: '4').persistable_attributes.should == {'a' => '4'}
    end
  end
  describe "create" do
    let(:node) { double('unwrapped_node', props: {a:2}) }

    it "creates a node" do
      @session.should_receive(:create_node).with({'a' => 1}, [:MyThing]).and_return(node)
      thing = MyThing.create(a:1)
      thing.attributes.should == {'a' => 2, 'x' => nil} # always reads the result from the database
      thing.class.should == MyThing
    end
  end

  describe "save" do
    let(:node) { double('unwrapped_node', props: {a:3}) }

    it 'saves the properties' do
      pending
      @session.should_receive(:create_node).with({x:42}, [:MyThing]).and_return(node)
      thing = MyThing.new(x: 42)
      thing.attributes.should == {'x' => 42} # always reads the result from the database
      thing.save
      thing.attributes.should == {'a' => 3} # always reads the result from the database
    end
  end

  #  describe "update" do
  #    let(:node) { double('unwrapped_node', props: {a:3}) }
  #
  #    it 'updates local properties and save all changed properties' do
  #      @session.should_receive(:create_node).with({x:42}, [:MyThing]).and_return(node)
  #      thing = MyThing.new(x: 42)
  #      thing._properties.should == {x:42} # always reads the result from the database
  #      thing.save
  #      thing._properties.should == {a:3} # always reads the result from the database
  #
  #    end
  #end
end

