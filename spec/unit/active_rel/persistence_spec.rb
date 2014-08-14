require 'spec_helper'

describe Neo4j::ActiveRel::Persistence do
  let(:session) { double("Session")}
  let(:node1) { double('first persisted node') }
  let(:node2) { double('second persisted node')}
  let(:rel)   { double('a persisted rel')  }

  before do
    node1.stub(:neo_id).and_return(1)
    node2.stub(:neo_id).and_return(2)
    @session = double('Mock Session')
    Neo4j::Session.stub(:current).and_return(@session)
    clazz.stub(:neo4j_session).and_return(session)
  end

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveRel::Initialize
      include Neo4j::ActiveRel::Persistence
      include Neo4j::ActiveRel::Property

      from_class Class
      to_class   Class

      type :friends_with

      property :friends_since
      property :level, type: Integer
    end
  end

  describe 'initialize' do
    it 'can take a hash of properties' do
      r = clazz.new(friends_since: 'sunday', level: 9001)
      expect(r.props).to eq(friends_since: 'sunday', level: 9001)
    end

    it 'raises an error when given a property which is not defined' do
      expect { clazz.new(unknown: true) }.to raise_error(Neo4j::Library::Property::UndefinedPropertyError)
    end
  end

  describe 'save' do
    it 'creates a relationship if not already persisted' do
      start_props = { from_node: node1, to_node: node2, friends_since: 'sunday', level: 9001 }
      end_props   = { friends_since: 'sunday', level: 9001, _classname: Class }
      r = clazz.new(start_props)
      expect(node1).to receive(:create_rel).with(:friends_with, node2, {friends_since: 'sunday', level: 9001, _classname: nil}).and_return(rel)
      rel.stub(:props).and_return(end_props)
      expect(r.save).to be_truthy 
    end

    it 'does not update the rel if nothing changes' do
      r = clazz.new(to_node: node1, from_node: node2, friends_since: 'sunday', level: 9001)
      r.stub(:_persisted_obj).and_return(rel)
      r.stub(:changed_attributes).and_return({})
      expect(rel).to receive(:exist?).and_return(true)
      r.save
    end

    it 'commits changes to an existing relationship' do
      r = clazz.new(to_node: node1, from_node: node2, friends_since: 'forever')
      r.stub(:_persisted_obj).and_return(rel)
      expect(rel).to receive(:exist?).and_return(true)
      expect(rel).to receive(:update_props).and_return(friends_since: 'forever')
      expect(r.save).to be_truthy
    end
  end

  describe 'save!' do
    it 'raises an exception if invalid' do
      clazz.any_instance.stub(:save).and_return(false)
      clazz.any_instance.stub_chain('errors.full_messages').and_return([])
      expect do
        clazz.new.save!
      end.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end
  end

  describe 'create' do
    it 'creates a new relationship' do
      expect(clazz).to receive(:extract_association_attributes!).twice.and_return(from_node: node1, to_node: node2)
      node1.stub(:create_rel).and_return(rel)
      rel.stub(:props).and_return(friends_since: 'yesterday', level: 5)
      expect(clazz.create(from_node: node1, to_node: node2, friends_since: 'yesterday', level: 5)).to be_truthy
    end
  end

  describe 'create!' do
    it 'raises an exception if invalid' do
      clazz.stub(:create).and_return(false)
      clazz.stub_chain('errors.full_messages').and_return([])
      expect do 
        clazz.create!
      end.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end
  end
end