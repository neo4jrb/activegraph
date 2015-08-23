require 'spec_helper'

describe Neo4j::ActiveNode::Persistence do
  let(:node) { double('a persisted node', exist?: true) }

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode::Persistence
      include Neo4j::ActiveNode::Unpersisted
      include Neo4j::ActiveNode::HasN
      include Neo4j::ActiveNode::Property

      property :name
      property :age, type: Integer

      def self.fetch_upstream_primitive(_)
        nil
      end
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
    let(:session) { double('Session') }
    before do
      @session = double('Mock Session')
      Neo4j::Session.stub(:current).and_return(session)
    end

    # TODO: This should be an e2e test. This stubbing...
    it 'creates a new node if not persisted before' do
      o = clazz.new(name: 'kalle', age: '42')
      o.stub(:serialized_properties).and_return({})
      allow_any_instance_of(Object).to receive(:serialized_properties_keys).and_return([])
      clazz.stub(:cached_class?).and_return(false)
      clazz.should_receive(:neo4j_session).and_return(session)
      clazz.should_receive(:mapped_label_names).and_return(:MyClass)
      node.should_receive(:props).and_return(name: 'kalle2', age: '43')
      session.should_receive(:create_node).with({name: 'kalle', age: 42}, :MyClass).and_return(node)
      clazz.any_instance.should_receive(:init_on_load).with(node, age: '43', name: 'kalle2')
      allow(Object).to receive(:default_property_values).and_return({})
      o.save
    end

    it 'does not update persisted node if nothing changed' do
      o = clazz.new(name: 'kalle', age: '42')
      o.stub(:_persisted_obj).and_return(node)
      o.stub(:changed_attributes).and_return({})
      expect(node).not_to receive(:update_props).with(anything)
      o.save
    end

    it 'updates node if already persisted before if an attribute was changed' do
      o = clazz.new
      o.name = 'sune'
      o.stub(:serialized_properties).and_return({})
      o.stub(:_persisted_obj).and_return(node)
      allow_any_instance_of(Object).to receive(:serialized_properties_keys).and_return([])

      expect(node).to receive(:update_props).and_return(name: 'sune')
      o.save
    end

    describe 'with cached_class? true' do
      it 'adds a _classname property' do
        clazz.stub(:default_property_values).and_return({})
        clazz.stub(:cached_class?).and_return(true)
        start_props = {name: 'jasmine', age: 5}
        end_props   = {name: 'jasmine', age: 5, _classname: 'MyClass'}
        o = clazz.new

        o.stub(:props).and_return(start_props)
        o.stub(:serialized_properties).and_return({})
        o.class.stub(:name).and_return('MyClass') # set_classname looks for this
        clazz.stub(:neo4j_session).and_return(session)

        clazz.stub(:mapped_label_names).and_return(:MyClass)
        expect(session).to receive(:create_node).with(end_props, :MyClass).and_return(node)
        expect(o).to receive(:init_on_load).with(node, end_props)
        allow_any_instance_of(Object).to receive(:serialized_properties_keys).and_return([])

        expect(node).to receive(:props).and_return(end_props)

        o.save
      end
    end
  end

  describe 'new_record?' do
    it 'is true if it does not wrap a persisted node' do
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
      o.props.should eq(age: 18)
    end
  end

  describe 'props_for_create' do
    let(:node) { clazz.new }
    before do
      clazz.send(:include, Neo4j::ActiveNode::IdProperty)
      clazz.id_property :uuid, auto: :uuid, constraint: false
      allow(clazz).to receive(:cached_class?).and_return false
    end

    it 'adds the primary key' do
      expect(node.props_for_create).to have_key(:uuid)
    end

    # This is important to be aware of. The UUID will be rebuilt each time it is called.
    it 'rebuilds each time called, setting a new UUID value' do
      props1 = node.props_for_create
      props2 = node.props_for_create
      expect(props1[:uuid]).not_to eq(props2[:uuid])
    end
  end
end
