module Neo4j
  module Shared
    describe QueryFactory do
      before do
        stub_active_node_class('NodeClass') {}

        stub_active_rel_class('RelClass') do
          from_class false
          to_class false
        end
      end

      describe '.factory_for' do
        subject { described_class.factory_for(graph_obj) }

        context 'with ActiveRel' do
          let(:graph_obj) { RelClass.new }
          it { is_expected.to eq RelQueryFactory }
        end

        context 'with ActiveNode' do
          let(:graph_obj) { NodeClass.new }
          it { is_expected.to eq NodeQueryFactory }
        end

        context 'with RelatedNode' do
          let(:graph_obj) { Neo4j::ActiveRel::RelatedNode.new(NodeClass.new) }
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
