describe 'Neo4j::ActiveNode' do
  let(:transaction) { double('Mock transaction', close: true) }
  let(:session) { double('Mock Session', create_node: nil, begin_tx: transaction) }

  before do
    stub_active_node_class 'MyThing' do
      property :a
      property :x
      has_one :out, :parent, model_class: false, type: nil
    end

    stub_named_class('MyNodeWithValidations', MyThing) do
      validates :x, presence: true
    end
    allow(SecureRandom).to receive(:uuid) { 'secure123' }
    allow(Neo4j::Session).to receive(:current).and_return(session)
  end

  describe 'new' do
    it 'does not allow setting undeclared properties' do
      expect(MyThing.new(a: '4').props).to eq(a: '4')
    end

    it 'undefined properties are found with the attributes method' do
      expect(MyThing.new(a: '4').attributes).to eq('a' => '4', 'x' => nil)
    end
  end

  describe 'create' do
    it 'does not store nil values' do
      node = double('unwrapped_node', props: {a: 999})
      expect(session).to receive(:create_node).with({a: 1, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 1)
      expect(thing.props).to eq(a: 999)
    end

    it 'stores undefined attributes' do
      node = double('unwrapped_node', props: {a: 999})
      expect(session).to receive(:create_node).with({a: 1, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 1)
      expect(thing.attributes).to eq('a' => 999, 'x' => nil) # always reads the result from the database
    end

    it 'does not allow to set undeclared properties using create' do
      expect(session).not_to receive(:create_node)
      expect { MyThing.create(bar: 43) }.to raise_error Neo4j::Shared::Property::UndefinedPropertyError
    end
  end

  describe '#save' do
    let(:node) { double('unwrapped_node', props: {a: 3}) }

    it 'saves declared the properties that has been changed with []= operator' do
      expect(session).to receive(:create_node).with({x: 42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.new
      thing[:x] = 42
      thing.save
    end

    it 'raise Neo4j::Shared::UnknownAttributeError if trying to set undeclared property' do
      thing = MyThing.new
      expect { thing[:newp] = 42 }.to raise_error(Neo4j::UnknownAttributeError)
    end
  end

  describe '#save!' do
    let(:node) { double('unwrapped_node', props: {a: 3}) }

    it 'returns true on success' do
      expect(session).to receive(:create_node).with({x: 42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.new
      thing[:x] = 42
      expect(thing.save!).to be true
    end

    context 'with validations' do
      it 'raises an error with invalid params' do
        thing = MyNodeWithValidations.new
        expect { thing.save! }.to raise_error(Neo4j::ActiveNode::Persistence::RecordInvalidError)
      end
    end
  end

  describe 'update_model' do
    let(:node) { double('unwrapped_node', props: {a: 3}) }

    it 'does not save unchanged properties' do
      expect(session).to receive(:create_node).with({a: 'foo', x: 44, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 'foo', x: 44)

      # only change X
      expect(node).to receive(:update_props).with(x: 32)
      thing.x = 32
      thing.send(:update_model)
    end

    it 'handles nil properties' do
      expect(session).to receive(:create_node).with({a: 'foo', x: 44, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing = MyThing.create(a: 'foo', x: 44)

      expect(node).to receive(:update_props).with(x: nil)
      thing.x = nil
      thing.send(:update_model)
    end
  end

  describe 'update_attribute' do
    let(:node) { double('unwrapped_node', props: {a: 111}) }

    let(:thing) do
      MyThing.new
    end

    it 'updates given property' do
      expect(session).to receive(:create_node).with({a: 42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing.update(a: 42)
    end

    it 'does not update it if it is not valid' do
      allow(thing).to receive(:valid?).and_return(false)
      expect(thing.update_attribute(:a, 42)).to be false
    end
  end

  describe 'update_attributes' do
    let(:node) { double('unwrapped_node', props: {a: 111}) }

    let(:thing) do
      MyThing.new
    end

    it 'updates given properties' do
      expect(session).to receive(:create_node).with({a: 42, x: 'hej', uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing.update_attributes(a: 42, x: 'hej')
    end

    it 'does not update it if it is not valid' do
      allow(thing).to receive(:valid?).and_return(false)
      expect(thing.update_attributes(a: 42)).to be false
    end
  end

  describe 'update_attribute!' do
    let(:node) { double('unwrapped_node', props: {a: 111}) }

    let(:thing) do
      MyThing.new
    end

    it 'updates given property' do
      expect(session).to receive(:create_node).with({a: 42, uuid: 'secure123'}, [:MyThing]).and_return(node)
      thing.update_attribute!(:a, 42)
    end

    it 'does raise an exception if not valid' do
      allow(thing).to receive(:valid?).and_return(false)
      expect { thing.update_attribute!(:a, 42) }.to raise_error(Neo4j::ActiveNode::Persistence::RecordInvalidError)
    end
  end
end
