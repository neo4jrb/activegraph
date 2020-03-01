module ActiveGraph
  module Shared
    describe QueryFactory do
      before do
        stub_node_class('NodeClass') {}

        stub_relationship_class('RelClass') do
          from_class false
          to_class false
        end
      end

      describe '.factory_for' do
        subject { described_class.factory_for(graph_obj) }

        context 'with Relationship' do
          let(:graph_obj) { RelClass.new }
          it { is_expected.to eq RelQueryFactory }
        end

        context 'with Node' do
          let(:graph_obj) { NodeClass.new }
          it { is_expected.to eq NodeQueryFactory }
        end

        context 'with RelatedNode' do
          let(:graph_obj) { ActiveGraph::Relationship::RelatedNode.new(NodeClass.new) }
          it { is_expected.to eq NodeQueryFactory }
        end

        context 'with anything else' do
          let(:graph_obj) { 'foo' }
          it { expect { subject }.to raise_error RuntimeError, /Unable to find factory for/ }
        end
      end
    end
  end
end
