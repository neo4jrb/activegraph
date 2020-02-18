describe ActiveGraph::Node::Persistence do
  let(:node) { double('a persisted node', exist?: true) }

  let(:clazz) do
    Class.new do
      include ActiveGraph::Shared
      include ActiveGraph::Shared::Identity
      include ActiveGraph::Node::Query
      include ActiveGraph::Node::Persistence
      include ActiveGraph::Node::Unpersisted
      include ActiveGraph::Node::HasN
      include ActiveGraph::Node::Property

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
      expect { clazz.new(unknown: true) }.to raise_error(ActiveGraph::Shared::Property::UndefinedPropertyError)
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
      clazz.send(:include, ActiveGraph::Node::IdProperty)
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
