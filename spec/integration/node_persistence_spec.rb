require 'spec_helper'

describe "Neo4j::ActiveNode" do

  class MyThing
    include Neo4j::ActiveNode
    property :a
    property :x
  end


  before do
    @session = double("Mock Session")
    Neo4j::Session.stub(:current).and_return(@session)
  end

  describe 'new' do
    it 'does not allow setting undeclared properties' do
      MyThing.new(a: '4').props.should == {:a => '4'}
    end

    it 'undefined properties are found with the attributes method' do
      MyThing.new(a: '4').attributes.should == {'a' => '4', 'x' => nil}
    end

  end

  describe "create" do
    it "does not store nil values" do
      node = double('unwrapped_node', props: {a:2})
      @session.should_receive(:create_node).with({a: 1}, [:MyThing]).and_return(node)
      thing = MyThing.create(a:1)
      thing.props.should == {a: 2}
    end

    it 'stores undefined attributes' do
      node = double('unwrapped_node', props: {a:2})
      @session.should_receive(:create_node).with({a: 1}, [:MyThing]).and_return(node)
      thing = MyThing.create(a:1)
      thing.attributes.should == {"a" => 2, "x" => nil} # always reads the result from the database
    end

    it 'does not allow to set undeclared properties using create' do
      node = double('unwrapped_node', props: {})
      @session.should_receive(:create_node).with({}, [:MyThing]).and_return(node)
      thing = MyThing.create(bar: 43)
      thing.props.should == {}
    end
  end

  describe "save" do
    let(:node) { double('unwrapped_node', props: {a:3}) }

    it 'saves declared the properties that has been changed with []= operator' do
      @session.should_receive(:create_node).with({x:42}, [:MyThing]).and_return(node)
      thing = MyThing.new
      thing[:x] = 42
      thing.save
    end


    it 'saves undeclared the properties that has been changed with []= operator' do
      @session.should_receive(:create_node).with({newp:42, foo: 'BAR'}, [:MyThing]).and_return(node)
      thing = MyThing.new
      thing[:newp] = 42
      thing[:foo] = "BAR"
      thing.save
    end

  end

    describe "update" do
      let(:node) { double('unwrapped_node', props: {a:3}) }

      it 'updates local properties and save all changed properties' do
        @session.should_receive(:create_node).with({}, [:MyThing]).and_return(node)
        node.should_receive(:props=).with(x: 44, y: 32)
        thing = MyThing.create()
        thing.update(x: 44, y: 32)
      end
  end
end

