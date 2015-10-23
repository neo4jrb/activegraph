require 'spec_helper'

describe Neo4j::Shared::QueryFactory do
  before do
    stub_active_node_class('FactoryFromClass') do
      property :name
    end

    stub_active_node_class('FactoryToClass') do
      property :name
    end

    stub_active_rel_class('FactoryRelClass') do
      property :score
    end
  end

  let(:from_node) { FactoryFromClass.new(name: 'foo') }
  let(:to_node) { FactoryToClass.new(name: 'bar') }
  let(:rel) { FactoryRelClass.new(score: 9000) }


  describe 'nodes' do
    let(:factory) { described_class.create(from_node, :from_node) }
    context 'unpersisted' do
      it 'builds a query to create' do
        expect do
          expect(factory.query.pluck(:from_node).first).to be_a(FactoryFromClass)
        end.to change { FactoryFromClass.count }
      end
    end

    context 'persisted' do
      before { from_node.save }

      it 'builds a query to match' do
        expect do
          expect(factory.query.pluck(:from_node).first.class.name).to eq 'FactoryFromClass'
        end.not_to change { FactoryFromClass.count }
      end
    end
  end
end
