require 'spec_helper'

describe Neo4j::ActiveNode::Persistence do
  let(:node) { double("a persisted node") }

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode::Persistence
      include Neo4j::ActiveNode::HasN
      include Neo4j::ActiveNode::Property

      property :name
      property :age, type: Integer
    end
  end

  describe 'initialize' do
    it 'can take a hash of properties' do
      o = clazz.new(name: 'kalle', age: '42')
      o.props.should eq(name: 'kalle', age: 42)
    end

    it 'raises an error when given a property which is not defined' do
      expect { clazz.new(unknown: true) }.to raise_error(Neo4j::Shared::Property::UndefinedPropertyError)
    end
  end

  describe 'save' do
    let(:session) { double("Session")}
    before do
      @session = double("Mock Session")
      Neo4j::Session.stub(:current).and_return(session)
    end

    it 'creates a new node if not persisted before' do
      o = clazz.new(name: 'kalle', age: '42')
      o.stub(:_persisted_obj).and_return(nil)
      clazz.stub(:cached_class?).and_return(false)
      clazz.should_receive(:neo4j_session).and_return(session)
      clazz.should_receive(:mapped_label_names).and_return(:MyClass)
      node.should_receive(:props).and_return(name: 'kalle2', age: '43')
      session.should_receive(:create_node).with({name: 'kalle', age: 42}, :MyClass).and_return(node)
      clazz.any_instance.should_receive(:init_on_load).with(node, age: "43", name: "kalle2")
      o.save
    end

    it 'does not updates node if already persisted before but nothing changed' do
      o = clazz.new(name: 'kalle', age: '42')
      o.stub(:_persisted_obj).and_return(node)
      o.stub(:changed_attributes).and_return({})
      node.should_receive(:exist?).and_return(true)
      o.save
    end

    it 'updates node if already persisted before if an attribute was changed' do
      o = clazz.new
      o.name = 'sune'
      o.stub(:_persisted_obj).and_return(node)
      node.should_receive(:exist?).and_return(true)
      node.should_receive(:update_props).and_return(name: 'sune')
      o.save
    end

    describe 'with cached_class? true' do
      it 'adds a _classname property' do
        clazz.stub(:cached_class?).and_return(true)
        start_props = { name: 'jasmine', age: 5 }
        end_props   = { name: 'jasmine', age: 5, _classname: 'MyClass' }
        o = clazz.new

        o.stub(:props).and_return(start_props)
        o.class.stub(:name).and_return('MyClass') #set_classname looks for this
        o.stub(:_persisted_obj).and_return(nil)
        clazz.stub(:neo4j_session).and_return(session)

        clazz.stub(:mapped_label_names).and_return(:MyClass)
        expect(session).to receive(:create_node).with(end_props, :MyClass).and_return(node)
        expect(o).to receive(:init_on_load).with(node, end_props)
        expect(node).to receive(:props).and_return(end_props)

        o.save
      end
    end
  end

  describe 'persisted?' do
    it 'is true if there is a wrapped node and it has not been deleted' do
      clazz.any_instance.stub(:_persisted_obj).and_return(node)
      o = clazz.new
      node.should_receive(:exist?).and_return(true)
      o.persisted?.should eq(true)
    end

    it 'is false if there is a wrapped node and it but it has been deleted' do
      clazz.any_instance.stub(:_persisted_obj).and_return(node)
      o = clazz.new
      node.should_receive(:exist?).and_return(false)
      o.persisted?.should eq(false)
    end

    it 'is false if there is not a persisted node' do
      clazz.any_instance.stub(:_persisted_obj).and_return(nil)
      o = clazz.new
      o.persisted?.should eq(false)
    end

  end

  describe 'new_record?' do
    it 'is true if it does not wrap a persisted node' do
      clazz.any_instance.stub(:_persisted_obj).and_return(nil)
      o = clazz.new
      o.new_record?.should eq(true)
    end

    it 'is false if it does wrap a persisted node' do
      clazz.any_instance.stub(:_persisted_obj).and_return(node)
      o = clazz.new
      o.new_record?.should eq(false)
    end
  end

  describe 'props' do
    it 'returns type casted attributes and undeclared attributes' do
      o = clazz.new
      o.age = '18'
      o.age.should eq(18)
    end

    it 'does not return undefined properties' do
      o = clazz.new # name not defined
      o.age = '18'
      o.props.should eq({:age => 18})
    end

  end

end
