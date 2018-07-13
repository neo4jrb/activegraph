describe Neo4j::ActiveNode::Scope::ScopeEvalContext do
  describe 'method missing' do
    let(:target) { double('target') }
    let(:query_proxy) { double(base: 'Chunky') }
    subject { described_class.new(target, query_proxy).base }

    it { is_expected.to eq('Chunky') }
  end
end
