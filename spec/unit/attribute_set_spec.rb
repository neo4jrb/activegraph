describe Neo4j::AttributeSet do
  before do
    stub_active_node_class('MyModel') do
      property :name, type: String
    end
  end

  describe '#method_missing' do
    let(:first_node) { MyModel.create(name: 'foo') }
    let(:attributes) { first_node.instance_variable_get(:@attributes) }

    it 'delegates method_missing to attribute Hash' do
      delegated_hash = attributes.instance_variable_get(:@attributes).send(:materialize)
      expect(delegated_hash).to receive(:has_key?).with('name')
      attributes.has_key?('name')
    end
  end
end
