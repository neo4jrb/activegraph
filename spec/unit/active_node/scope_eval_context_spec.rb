describe ActiveGraph::Node::Scope::ScopeEvalContext do
  describe 'method missing' do
    let(:query_proxy) { double('QueryProxy', query: double) }
    subject { described_class.new(nil, query_proxy) }

    it 'should delegate non existant method call to query_proxy' do
      expect(query_proxy).to receive(:query)
      subject.query
    end

    it 'should call method_missing of query_proxy in case method deos not exist on query_proxy' do
      expect(query_proxy).to receive(:method_missing).with(:non_existent_method)
      subject.non_existent_method
    end
  end
end
