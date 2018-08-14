describe Neo4j::ActiveNode::Scope::ScopeEvalContext do
  describe 'method missing' do
    let(:target) { double('target') }
    let(:query_proxy) { Book.all }
    before(:example) do
      stub_active_node_class('Book')
    end
    subject { described_class.new(target, query_proxy) }

    it 'should delegate non existant method call to query_proxy' do
      expect(subject).to receive(:query)
      subject.query
    end

    it 'should call method_missing of query_proxy in case method deos not exist on query_proxy' do
      expect(query_proxy).to receive(:method_missing)
      subject.non_existent_method
    end
  end
end
