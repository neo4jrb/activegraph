describe ActiveGraph::Node::Initialize do
  before do
    stub_node_class('MyModel') do
      property :name, type: String
    end
  end

  describe '@attributes' do
    let(:first_node) { MyModel.create(name: 'foo') }
    let(:attributes) { first_node.instance_variable_get(:@attributes) }
    let(:keys) { attributes.keys }

    it '@attributes are AttributeSet' do
      expect(attributes).to be_kind_of(ActiveGraph::AttributeSet)
    end

    it 'sets @attributes with the expected properties' do
      expect(keys).to eq(['name', ('uuid' unless MyModel.id_property_name == :neo_id)].compact)
    end
  end
end
