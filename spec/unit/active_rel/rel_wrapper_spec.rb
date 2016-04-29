describe Neo4j::RelWrapping do
  let(:id) { 1 }
  let(:type) { :DEFAULT }
  let(:properties) { {} }
  let(:start_node_id) { 1 }
  let(:end_node_id) { 2 }

  let(:rel) { Neo4j::Core::Relationship.new(id, type, properties, start_node_id, end_node_id) }

  subject { Neo4j::RelWrapping.wrapper(rel) }

  it { should eq(rel) }

  context 'HasFoo ActiveRel class defined' do
    before do
      stub_active_rel_class('HasFoo') do
        property :bar
        property :biz
      end
    end

    let_context type: :HAS_FOO do
      it { should be_a(HasFoo) }

      let_context(properties: {'bar' => 'baz', 'biz' => 1}) do
        its(:bar) { should eq('baz') }
        its(:biz) { should eq(1) }

        its('start_node.neo_id') { should eq(1) }
        its('end_node.neo_id') { should eq(2) }
      end
    end
  end
end
