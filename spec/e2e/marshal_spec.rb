describe ActiveGraph::Shared::Marshal, :ffi_only do
  describe 'ActiveNode' do
    before do
      stub_active_node_class('Parent')

      stub_named_class('Child', Parent) do
        property :foo
      end
    end

    let(:node) { Child.create(foo: 'bar') }

    it 'marshals correctly' do
      id = node.id
      neo_id = node.neo_id
      unmarshaled = Marshal.load(Marshal.dump(node))

      expect(unmarshaled).to be_a(Child)
      expect(unmarshaled.id).to eq(id)
      expect(unmarshaled.neo_id).to eq(neo_id)
      expect(unmarshaled.foo).to eq('bar')
      expect(unmarshaled.labels).to match_array([:Parent, :Child])
      expect(unmarshaled._persisted_obj).to be_a(ActiveGraph::Core::Node)
    end
  end

  describe 'ActiveRel' do
    before do
      stub_active_node_class('Person')

      stub_active_rel_class('HasParent') do
        from_class :Person
        to_class :Person

        property :foo
      end
    end

    let(:rel) { HasParent.create(Person.create, Person.create, foo: 'bar') }

    it 'marshals correctly' do
      neo_id = rel.neo_id
      unmarshaled = Marshal.load(Marshal.dump(rel))

      expect(unmarshaled).to be_a(HasParent)
      expect(unmarshaled.neo_id).to eq(neo_id)
      expect(unmarshaled.foo).to eq('bar')
      expect(unmarshaled.type).to eq('HAS_PARENT')
      expect(unmarshaled._persisted_obj).to be_a(ActiveGraph::Core::Relationship)
    end
  end
end
