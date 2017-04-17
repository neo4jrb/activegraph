require 'spec_helper'

describe Neo4j::ActiveNode::Validations do
  let(:node) { double('a persisted node') }
  before(:each) { clazz.any_instance.stub(:_persisted_obj).and_return(nil) }

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode::Persistence
      include Neo4j::ActiveNode::Unpersisted
      include Neo4j::ActiveNode::HasN
      include Neo4j::ActiveNode::Property
      include Neo4j::ActiveNode::Validations

      property :name
      property :age, type: Integer

      validates :name, presence: true

      def self.mapped_label_names
        :MyClass
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, 'MyClass')
      end

      def self.fetch_upstream_primitive(_attr)
        nil
      end
    end
  end

  describe 'save' do
    let(:session) { double('Session') }
    before do
      @session = double('Mock Session')
      Neo4j::Session.stub(:current).and_return(session)
    end

    context 'when valid' do
      it 'creates a new node if not persisted before' do
        o = clazz.new(name: 'kalle', age: '42')
        o.stub(:_persisted_obj).and_return(nil)
        o.stub(:serialized_properties).and_return({})
        o.serialized_properties
        clazz.stub(:default_property_values).and_return({})
        clazz.stub(:cached_class?).and_return(false)
        clazz.should_receive(:neo4j_session).and_return(session)
        node.should_receive(:props).and_return(name: 'kalle2', age: '43')
        session.should_receive(:create_node).with({name: 'kalle', age: 42}, :MyClass).and_return(node)
        o.should_receive(:init_on_load).with(node, age: '43', name: 'kalle2')
        allow(Object).to receive(:serialized_properties_keys).and_return([])
        o.save.should be true
      end

      it 'updates node if already persisted before if an attribute was changed' do
        o = clazz.new
        o.name = 'sune'
        o.stub(:_persisted_obj).and_return(node)
        o.stub(:serialized_properties).and_return({})
        node.should_receive(:update_props).and_return(name: 'sune')
        allow(Object).to receive(:serialized_properties_keys).and_return([])
        o.save.should be true
      end
    end

    context 'when not valid' do
      it 'does not create a new node' do
        o = clazz.new(age: '42')
        o.stub(:_persisted_obj).and_return(nil)
        o.save.should be false
      end

      it 'does not update a node' do
        o = clazz.new
        o.age = '42'
        o.stub(:_persisted_obj).and_return(node)
        o.save.should be false
      end
    end
  end
end
