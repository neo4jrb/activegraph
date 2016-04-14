describe Neo4j::ActiveNode do
  before do
    stub_active_node_class('SimpleClass') do
      property :name
    end
  end

  describe 'SimpleClass' do
    context 'when instantiated with new()' do
      subject do
        SimpleClass.new
      end

      it 'does not have any attributes' do
        expect(subject.attributes).to eq('name' => nil)
      end

      it 'returns nil when asking for a attribute' do
        expect(subject['name']).to be_nil
      end

      it 'can set attributes' do
        subject['name'] = 'foo'
        expect(subject['name']).to eq('foo')
      end

      it 'allows symbols instead of strings in [] and []= operator' do
        subject[:name] = 'foo'
        expect(subject['name']).to eq('foo')
        expect(subject[:name]).to eq('foo')
      end

      it 'allows setting attributes to nil' do
        subject['name'] = nil
        expect(subject['name']).to be_nil
        subject['name'] = 'foo'
        subject['name'] = nil
        expect(subject['name']).to be_nil
      end
    end

    context 'when instantiated with new(name: "foo")' do
      subject { SimpleClass.new(unknown: 'foo') }

      it 'does not allow setting undeclared properties' do
        expect { subject }.to raise_error Neo4j::Shared::Property::UndefinedPropertyError
      end
    end
  end

  describe 'question mark methods' do
    let(:node) { SimpleClass.new }

    it 'is false when unset' do
      expect(node.name?).to eq false
    end

    context 'value is true' do
      it 'changes when the value is present' do
        expect { node.name = 'true' }.to change { node.name? }.from(false).to(true)
      end
    end
  end

  describe '#query_attribute' do
    let(:node) { SimpleClass.new }

    subject { node.query_attribute(method_name) }

    context 'attribute is defined' do
      let(:method_name) { :name }

      it 'calls the question mark method' do
        expect(node).to receive(:name?)
        subject
      end
    end

    context 'attribute is not defined' do
      let(:method_name) { :foo }

      it do
        expect { subject }.to raise_error Neo4j::UnknownAttributeError
      end
    end
  end
end
