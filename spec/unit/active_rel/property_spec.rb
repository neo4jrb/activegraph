require 'spec_helper'

describe Neo4j::ActiveRel::Property do
  let(:session) { double("Session")}

  before do
    @session = double('Mock Session')
    Neo4j::Session.stub(:current).and_return(@session)
    clazz.stub(:neo4j_session).and_return(session)
  end

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveRel::Property
    end
  end

  describe 'instance methods' do
    describe 'related nodes inbound/outbound' do
      it 'creates setters' do
        expect(clazz.new).to respond_to(:inbound=)
        expect(clazz.new).to respond_to(:outbound=)
      end

      it 'creates getters' do
        expect(clazz.new).to respond_to(:inbound)
        expect(clazz.new).to respond_to(:outbound)
      end

      it 'returns the @inbound and @outbound values' do
        r = clazz.new
        r.instance_variable_set(:@inbound, 'n1')
        r.instance_variable_set(:@outbound, 'n2')
        expect(r.inbound).to eq 'n1'
        expect(r.outbound).to eq 'n2'
      end
    end

    describe 'rel_type' do
      it 'returns the relationship type set in class' do
        clazz.rel_type 'myrel'
        expect(clazz.new.rel_type).to eq 'myrel'
      end
    end
  end

  describe 'class methods' do
    describe 'extract_relationship_attributes!' do
      it 'returns the inbound and outbound keys and values' do
        expect(clazz.extract_relationship_attributes!({inbound: 'test', outbound: 'test', name: 'chris'})).to eq(inbound: 'test', outbound: 'test')
        expect(clazz.extract_relationship_attributes!({inbound: 'test', name: 'chris'})).to eq(inbound: 'test')
        expect(clazz.extract_relationship_attributes!({outbound: 'test', name: 'chris'})).to eq(outbound: 'test')
      end
    end

    describe 'rel_type' do
      it 'sets @rel_type' do
        clazz.rel_type 'myrel'
        expect(clazz.instance_variable_get(:@rel_type)).to eq 'myrel'
      end
    end

    describe '_rel_type' do
      it 'returns the currently set rel type' do
        clazz.rel_type 'myrel'
        expect(clazz._rel_type).to eq 'myrel'
      end
    end

    describe 'load_entity' do
      it 'aliases Neo4j::Node.load' do
        expect(Neo4j::Node).to receive(:load).with(1).and_return(true)
        clazz.load_entity(1)
      end
    end
  end
end
