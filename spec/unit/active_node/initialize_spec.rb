describe Neo4j::ActiveNode::Initialize do
  before do
    stub_active_node_class('MyModel') do
      property :name, type: String
    end
  end

  describe '@attributes' do
    let(:first_node) { MyModel.create(name: 'foo') }
    let(:keys) { first_node.instance_variable_get(:@attributes).keys }

    it 'sets @attributes with the expected properties' do
      expect(keys).to eq(%w(name uuid))
    end
  end
end
