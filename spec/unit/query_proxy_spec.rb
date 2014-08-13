require 'spec_helper'

describe Neo4j::ActiveNode::Query::QueryProxy do
  let (:qp) { Neo4j::ActiveNode::Query::QueryProxy.new(Object) }
  let (:session) { double("A session")}
  let (:node) { double("A node object", foo: 'bar' ) }
  let (:rel)  { double("A rel object")}

  describe 'each_with_rel' do
    it 'yields a node and rel object' do
      expect(qp).to receive(:pluck).and_return([node, rel])
      expect(qp.each_with_rel{|n, r| }).to eq [node, rel]
    end
  end

  describe 'select_with_rel' do
    it 'passes true to :each and calls :select' do
      expect(qp).to receive(:each).with(true).and_return([node, rel])
      expect(qp.select_with_rel.to_a).to eq [node, rel]
    end

    it 'selects pairs of objects that match the criteria' do
      expect(qp).to receive(:each).exactly(2).times.with(true).and_return([[node, rel]])
      expect(node).to receive(:foo).exactly(2).times
      expect(rel).not_to receive(:foo)
      expect(qp.select_with_rel{|n, r| n.foo == 'bar' }).to eq [[node, rel]]
      expect(qp.select_with_rel{|n, r| n.foo == 'foo'}).to eq []
    end
  end

  describe 'to_cypher' do
    let(:query_result) { double("the result of calling :query")}
    it 'calls query.to_cypher' do
      expect(qp).to receive(:query).and_return(query_result)
      expect(query_result).to receive(:to_cypher).and_return(String)
      qp.to_cypher
    end
  end

  describe '_association_chain_var' do
    context 'when missing start_object and query_proxy' do
      it 'raises a crazy error' do
        expect{qp.send(:_association_chain_var)}.to raise_error 'Crazy error'
      end

      it 'needs a better error than "crazy error"'
    end
  end

  describe '_association_query_start' do
    context 'when missing start_object and query_proxy' do
      it 'raises a crazy error' do
        expect{qp.send(:_association_query_start, nil)}.to raise_error 'Crazy error'
      end

      it 'needs a better error than "crazy error"'
    end
  end
end
