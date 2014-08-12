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
    context 'with class :any' do
      it 'calls Neo4j::Session.query' do
        expect(clazz).to receive(:_from_class).and_return(:any)
        expect(clazz).to receive(:_to_class).and_return(:any)
        expect(Neo4j::Session).to receive(:query)
        clazz.where(name: 'superman')
      end
    end

    context 'with a model' do
      it 'calls :query_as on the outbound node' do
        expect(clazz).to receive(:_from_class).exactly(3).times.and_return(Object)
        expect(clazz).to receive(:_to_class).and_return(Object)

        expect(Object).to receive(:query_as).with(:n1).and_return(Object)
        expect(Object).to receive(:match).and_return(Object)
        expect(Object).to receive(:where).and_return({})
        clazz.where(name: 'superman')
      end
    end
  end

  describe 'each' do
    context 'with class :any' do
      it 'calls map and each' do
        h = {}
        expect(clazz).to receive(:_from_class).and_return(:any)
        clazz.instance_variable_set(:@query, QueryProxyDouble)
        expect(QueryProxyDouble).to receive(:map).and_return(h)
        expect(h).to receive(:each)
        clazz.each
      end
    end

    context 'with a model' do
      it 'calls pluck and each' do
        h = {}
        expect(clazz).to receive(:_from_class).and_return(Object)
        clazz.instance_variable_set(:@query, QueryProxyDouble)
        expect(QueryProxyDouble).to receive(:pluck).with(:r1).and_return(h)
        expect(h).to receive(:each)
        clazz.each
      end
    end
  end

  describe 'first' do
    context 'with class :any' do
      it 'calls map and first' do
        h = {}
        expect(clazz).to receive(:_from_class).and_return(:any)
        clazz.instance_variable_set(:@query, QueryProxyDouble)
        expect(QueryProxyDouble).to receive(:map).and_return(h)
        expect(h).to receive(:each)
        clazz.first
      end
    end

    context 'with a model' do
      it 'calls pluck and first' do
        h = {}
        expect(clazz).to receive(:_from_class).and_return(Object)
        clazz.instance_variable_set(:@query, QueryProxyDouble)
        expect(QueryProxyDouble).to receive(:pluck).with(:r1).and_return(h)
        expect(h).to receive(:first)
        clazz.first
      end
    end
  end

  describe 'cypher node string' do
    context 'when class is :any' do
      it 'returns the node identifier by itself' do
        expect(clazz).to receive(:_from_class).and_return(:any)
        expect(clazz).to receive(:_to_class).and_return(:any)

        expect(clazz.cypher_node_string(:outbound)).to eq 'n1'
        expect(clazz.cypher_node_string(:inbound)).to eq 'n2'
      end
    end

    context 'when class is an object' do
      it 'returns the node_identifier with the backtick-wrapped class name' do
        expect(clazz).to receive(:_from_class).and_return(Object)
        expect(clazz).to receive(:_to_class).and_return(Object)

        expect(clazz.cypher_node_string(:outbound)).to eq 'n1:`Object`'
        expect(clazz.cypher_node_string(:inbound)).to eq 'n2:`Object`'
      end
    end
  end

  describe 'where_string' do
    it 'makes a hash a valid cypher where string' do
      expect(clazz.send(:where_string, {foo: 'foo'})).to eq "r1.foo = 'foo'"
      expect(clazz.send(:where_string, {foo: 'foo', bar: 'bar'})).to eq "r1.foo = 'foo', r1.bar = 'bar'"
    end

    it 'does not wrap integers in quotes' do
      expect(clazz.send(:where_string, {foo: 'foo', age: 2})).to eq "r1.foo = 'foo', r1.age = 2"
    end
  end
end