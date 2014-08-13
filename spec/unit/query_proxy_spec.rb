require 'spec_helper'

describe Neo4j::ActiveNode::Query::QueryProxy do
  let (:qp) { Neo4j::ActiveNode::Query::QueryProxy.new(Object) }
  let (:session) { double("A session")}
  let (:node) { double("A node object") }
  let (:rel)  { double("A rel object")}

  describe 'each_with_rel' do
    it 'yields a node and rel object' do
      qp.instance_variable_set(:@node_var, :n1)
      qp.instance_variable_set(:@rel_var, :r1)
      expect(qp).to receive(:pluck).with(:n1, :r1).and_return([node, rel])
      expect(qp.each_with_rel{|n, r| }).to eq [node, rel]
    end

    it 'raises an error if there is no @rel_var' do
      expect{qp.each_with_rel{|n, r|}}.to raise_error 'No relationship identifier specified'
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
end