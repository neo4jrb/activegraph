describe ActiveGraph::Node::Validations do
  let(:node) { double('a persisted node') }
  before(:each) { allow_any_instance_of(clazz).to receive(:_persisted_obj).and_return(nil) }

  let(:clazz) do
    Class.new do
      include ActiveGraph::Shared
      include ActiveGraph::Shared::Identity
      include ActiveGraph::Node::Query
      include ActiveGraph::Node::Persistence
      include ActiveGraph::Node::Unpersisted
      include ActiveGraph::Node::HasN
      include ActiveGraph::Node::Property
      include ActiveGraph::Node::Validations

      property :name
      property :age, type: Integer

      validates :name, presence: true

      def self.mapped_label_names
        :MyClass
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, 'MyClass')
      end

      def self.fetch_upstream_primitive(_attr)
        nil
      end
    end
  end

  describe 'save' do
    context 'when valid' do
      it 'creates a new node if not persisted before' do
        o = clazz.new(name: 'kalle', age: '42')
        allow(o).to receive(:_persisted_obj).and_return(nil)
        allow(o).to receive(:serialized_properties).and_return({})
        o.serialized_properties
        allow(clazz).to receive(:default_property_values).and_return({})
        expect(node).to receive(:properties).and_return(name: 'kalle2', age: '43')
        expect(o).to receive(:_create_node).with({ name: 'kalle', age: 42 }).and_return(node)
        expect(o).to receive(:init_on_load).with(node, { age: '43', name: 'kalle2' })
        allow(Object).to receive(:serialized_properties_keys).and_return([])
        expect(o.save).to be true
      end
    end

    context 'when not valid' do
      it 'does not create a new node' do
        o = clazz.new(age: '42')
        allow(o).to receive(:_persisted_obj).and_return(nil)
        expect(o.save).to be false
      end

      it 'does not update a node' do
        o = clazz.new
        o.age = '42'
        allow(o).to receive(:_persisted_obj).and_return(node)
        expect(o.save).to be false
      end
    end
  end
end
