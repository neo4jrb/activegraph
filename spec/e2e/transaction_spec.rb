require 'spec_helper'

describe 'Neo4j::Transaction' do
  context 'reading has_one relationships' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        has_one :out, :thing, model_class: self
      end
    end

    it 'returns  hash values inside but outside it has the node value after commit' do
      tx = Neo4j::Transaction.new
      a = clazz.create name: 'a'
      b = clazz.create name: 'b'
      a.thing = b
      expect(a.thing).to eq("name"=>"b", "_classname"=>clazz.to_s)
      tx.close
      expect(a.thing).to eq(b)
    end
  end
end