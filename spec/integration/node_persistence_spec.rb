require 'spec_helper'

describe "Neo4j::ActiveNode" do

  class MyThing
    include Neo4j::ActiveNode
    property :a
    property :x
    has_one :out, :parent, model_class: false
  end


  before do
    SecureRandom.stub(:uuid) { 'secure123' }
    @session = double("Mock Session", create_node: nil)
    MyThing.stub(:cached_class?).and_return(false)
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
      node = double('unwrapped_node', props: {a: 999})
      @session.should_receive(:create_node).with({a: 1, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 1)
      thing.props.should == {a: 999}
    end

    it 'stores undefined attributes' do
      node = double('unwrapped_node', props: {a: 999})
      @session.should_receive(:create_node).with({a: 1, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 1)
      thing.attributes.should == {"a" => 999, "x" => nil} # always reads the result from the database
    end

    it 'does not allow to set undeclared properties using create' do
      node = double('unwrapped_node', props: {})
      @session.should_not_receive(:create_node)
      expect { MyThing.create(bar: 43) }.to raise_error Neo4j::Shared::Property::UndefinedPropertyError
    end

    # skip "SKIP, old tests, neo4j-core has been updated. Is this still needed?"
    # it 'can create relationships' do
    #   parent = double("parent node", neo_id: 1, persisted?: true)
    #   node = double('unwrapped_node', props: {a: 999}, rel: nil, neo_id: 2)
    #   node.class.stub(:mapped_label_name).and_return('MyThing')
    #   node.stub(:exist?).and_return(true)
    #   @session.should_receive(:create_node).with({a: 1}, [:MyThing]).and_return(node)
    #   @session.should_receive(:query).exactly(3).times.and_return(Neo4j::Core::Query.new)
    #   @session.should_receive(:_query).at_most(1000)
    #   #@session.should_receive(:begin_tx)
    #   thing = MyThing.create(a: 1,  parent: parent)
    #   thing.props.should == {a: 999}
    # end

    # it 'will delete old relationship before creating a new one' do
    #   parent = double("parent node", neo_id: 1, persisted?: true)
    #   old_rel = double("old relationship")

    #   node = double('unwrapped_node', props: {a: 999}, rel: old_rel, neo_id: 2)

    #   node.class.stub(:mapped_label_name).and_return('MyThing')
    #   node.stub(:exist?).and_return(true)
    #   @session.should_receive(:create_node).with({a: 1}, [:MyThing]).and_return(node)
    #   @session.should_receive(:query).exactly(3).times.and_return(Neo4j::Core::Query.new)
    #   @session.should_receive(:_query).exactly(2).times

    #   #@session.should_receive(:begin_tx)

    #   thing = MyThing.create(a: 1,  parent: parent)
    #   thing.props.should == {a: 999}
    # end
  end

  describe "save" do
    let(:node) { double('unwrapped_node', props: {a: 3}) }

    it 'saves declared the properties that has been changed with []= operator' do
      @session.should_receive(:create_node).with({x: 42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.new
      thing[:x] = 42
      thing.save
    end


    it 'raise ActiveAttr::UnknownAttributeError if trying to set undeclared property' do
      thing = MyThing.new
      expect { thing[:newp] = 42 }.to raise_error(ActiveAttr::UnknownAttributeError)
    end

  end

  describe "update_model" do
    let(:node) { double('unwrapped_node', props: {a: 3}) }

    it 'does not save unchanged properties' do
      @session.should_receive(:create_node).with({a: 'foo', x: 44, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 'foo', x: 44)

      # only change X
      node.should_receive(:update_props).with('x' => 32)
      thing.x = 32
      thing.send(:update_model)
    end

    it 'handles nil properties' do
      @session.should_receive(:create_node).with({a: 'foo', x: 44, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 'foo', x: 44)

      node.should_receive(:update_props).with('x' => nil)
      thing.x = nil
      thing.send(:update_model)
    end
  end

  describe 'update_attribute' do
    let(:node) { double('unwrapped_node', props: {a: 111}) }

    let(:thing) do
      MyThing.new
    end

    it 'updates given property' do
      expect(@session).to receive(:create_node).with({a:42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing.update(a: 42)
    end

    it 'does not update it if it is not valid' do
      thing.stub(:valid?).and_return(false)
      expect(thing.update_attribute(:a, 42)).to be false
    end

  end

  describe 'update_attributes' do
    let(:node) { double('unwrapped_node', props: {a: 111}) }

    let(:thing) do
      MyThing.new
    end

    it 'updates given properties' do
      expect(@session).to receive(:create_node).with({a:42, x: 'hej', uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing.update_attributes(a: 42, x: 'hej')
    end

    it 'does not update it if it is not valid' do
      thing.stub(:valid?).and_return(false)
      expect(thing.update_attributes(a: 42)).to be false
    end

  end

  describe 'update_attribute!' do
    let(:node) { double('unwrapped_node', props: {a: 111}) }

    let(:thing) do
      MyThing.new
    end

    it 'updates given property' do
      expect(@session).to receive(:create_node).with({a:42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing.update_attribute!(:a, 42)
    end

    it 'does raise an exception if not valid' do
      thing.stub(:valid?).and_return(false)
      expect{thing.update_attribute!(:a, 42)}.to raise_error(Neo4j::ActiveNode::Persistence::RecordInvalidError)
    end
  end
end
