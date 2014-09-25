require 'spec_helper'

describe 'Neo4j::Transaction' do
  context 'reading has_one relationships for Neo4j::Server' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        has_one :out, :thing, model_class: self
      end
    end

    #:nocov:
    it 'returns a wrapped node inside and outside of transaction' do
      i = 0
      SecureRandom.stub(:uuid) do
        i += 1
        "secure1234_#{i}"
      end

      if Neo4j::Session.current.db_type == :server_db
        clazz
        begin
          tx = Neo4j::Transaction.new
          a = clazz.create name: 'a'
          b = clazz.create name: 'b'
          a.thing = b
          # expect(a.thing).to eq("name"=>"b", "_classname"=>clazz.to_s, "uuid" => "secure1234_2")
          expect(a.thing).to eq b
        ensure
          tx.close
        end
        expect(a.thing).to eq(b)
      end

      if Neo4j::Session.current.db_type == :embedded_db
        clazz
        begin
          tx = Neo4j::Transaction.new
          a = clazz.create name: 'a'
          b = clazz.create name: 'b'
          a.thing = b
          expect(a.thing).to eq(b)
        ensure
          tx.close
        end
        expect(a.thing).to eq(b)
      end

    end
    #:nocov:
  end
end
