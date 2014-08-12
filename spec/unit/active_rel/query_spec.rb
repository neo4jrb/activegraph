require 'spec_helper'

describe Neo4j::ActiveRel::Query do
  class QueryProxyDouble; end
  let(:session) { double("Neo4j session") }
  let(:clazz) do
    Class.new do
      include Neo4j::ActiveRel::Query
    end
  end

  before do
    clazz.stub(:_outbound_class).and_return(Object)
    clazz.stub(:_inbound_class).and_return(Object)
    clazz.stub(:_type).and_return('mytype')
    clazz.stub(:neo4j_session).and_return(session)
  end

  describe 'find' do
    it 'calls find_by_id' do
      expect(clazz).to receive(:find_by_id).with(1, session)
      clazz.find(1)
    end
  end

  describe 'find_by_id' do
    it 'calls Neo4j::Relationship.load' do
      expect(Neo4j::Relationship).to receive(:load).with(1, session)
      clazz.find(1)
    end
  end

  describe 'where' do
    it 'calls :query_as on the outbound node' do
      expect(Object).to receive(:query_as).with(:n1).and_return(Object)
      expect(Object).to receive(:match).and_return(Object)
      expect(Object).to receive(:where).and_return({})
      clazz.where(name: 'superman')
    end
  end

  describe 'each' do
    it 'calls pluck and each' do
      h = {}
      clazz.instance_variable_set(:@query, QueryProxyDouble)
      expect(QueryProxyDouble).to receive(:pluck).with(:r1).and_return(h)
      expect(h).to receive(:each)
      clazz.each
    end
  end

  describe 'first' do
    it 'calls pluck and first' do
      h = {}
      clazz.instance_variable_set(:@query, QueryProxyDouble)
      expect(QueryProxyDouble).to receive(:pluck).with(:r1).and_return(h)
      expect(h).to receive(:first)
      clazz.first
    end
  end
end