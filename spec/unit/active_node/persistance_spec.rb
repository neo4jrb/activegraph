describe Neo4j::ActiveNode::Persistence do
  let(:node) { double('a persisted node', exist?: true) }

  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode::Persistence
      include Neo4j::ActiveNode::Unpersisted
      include Neo4j::ActiveNode::HasN
      include Neo4j::ActiveNode::Property

      property :name
      property :age, type: Integer

      def self.fetch_upstream_primitive(_)
        nil
      end
    end
  end

  describe 'initialize' do
    it 'can take a hash of properties' do
      o = clazz.new(name: 'kalle', age: '42')
      expect(o.props).to eq(name: 'kalle', age: 42)
    end

    it 'raises an error when given a property which is not defined' do
      expect { clazz.new(unknown: true) }.to raise_error(Neo4j::Shared::Property::UndefinedPropertyError)
    end
  end

  describe 'save' do
    let(:session) { double('Session') }
    before do
      @session = double('Mock Session')
      allow(Neo4j::Session).to receive(:current).and_return(session)
    end

    # TODO: This should be an e2e test. This stubbing...
    it 'creates a new node if not persisted before' do
      o = clazz.new(name: 'kalle', age: '42')
      allow(o).to receive(:serialized_properties).and_return({})
      allow_any_instance_of(Object).to receive(:serialized_properties_keys).and_return([])
      expect(clazz).to receive(:neo4j_session).and_return(session)
      expect(clazz).to receive(:mapped_label_names).and_return(:MyClass)
      expect(node).to receive(:props).and_return(name: 'kalle2', age: '43')
      expect(session).to receive(:create_node).with({name: 'kalle', age: 42}, :MyClass).and_return(node)
      expect_any_instance_of(clazz).to receive(:init_on_load).with(node, age: '43', name: 'kalle2')
      allow(Object).to receive(:default_property_values).and_return({})
      o.save
    end

    it 'does not update persisted node if nothing changed' do
      o = clazz.new(name: 'kalle', age: '42')
      allow(o).to receive(:_persisted_obj).and_return(node)
      allow(o).to receive(:changed_attributes).and_return({})
      expect(node).not_to receive(:update_props).with(anything)
      o.save
    end

    it 'updates node if already persisted before if an attribute was changed' do
      o = clazz.new
      o.name = 'sune'
      allow(o).to receive(:serialized_properties).and_return({})
      allow(o).to receive(:_persisted_obj).and_return(node)
      allow_any_instance_of(Object).to receive(:serialized_properties_keys).and_return([])

      expect(node).to receive(:update_props).and_return(name: 'sune')
      o.save
    end
  end

  describe 'new_record?' do
    it 'is true if it does not wrap a persisted node' do
      o = clazz.new
      expect(o.new_record?).to eq(true)
    end

    it 'is false if it does wrap a persisted node' do
      allow_any_instance_of(clazz).to receive(:_persisted_obj).and_return(node)
      o = clazz.new
      expect(o.new_record?).to eq(false)
    end
  end

  describe 'props' do
    it 'returns type casted attributes and undeclared attributes' do
      o = clazz.new
      o.age = '18'
      expect(o.age).to eq(18)
    end

    it 'does not return undefined properties' do
      o = clazz.new # name not defined
      o.age = '18'
      expect(o.props).to eq(age: 18)
    end
  end

  describe 'props_for_create' do
    let(:node) { clazz.new }
    before do
      clazz.send(:include, Neo4j::ActiveNode::IdProperty)
      clazz.id_property :uuid, auto: :uuid, constraint: false
    end

    it 'adds the primary key' do
      expect(node.props_for_create).to have_key(:uuid)
    end

    # This is important to be aware of. The UUID will be rebuilt each time it is called.
    it 'rebuilds each time called, setting a new UUID value' do
      props1 = node.props_for_create
      props2 = node.props_for_create
      expect(props1[:uuid]).not_to eq(props2[:uuid])
    end
  end
end
