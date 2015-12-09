class Neo4j::ActiveNode::HasN::Association
  describe RelWrapper do
    let(:type) { :FRIENDS_WITH }
    let(:identifier) { :r }
    let(:unique_props) { {} }
    let(:assoc_props) { {type: 'FRIENDS_WITH'}.merge(unique_props) }
    let(:association) { Neo4j::ActiveNode::HasN::Association.new(:has_many, :out, :friends, assoc_props) }
    let(:props) { {first: :foo, second: :bar, third: :baz, fourth: :buzz} }
    let(:wrapper) { described_class.new(association, props) }

    describe '#initialize' do
      it 'requires an Association and properties' do
        expect { wrapper }.not_to raise_error
        expect(wrapper.type).to eq type
        expect(wrapper.properties).to eq props
      end
    end

    describe 'identifiers' do
      it 'have defaults' do
        expect(wrapper.from_node_identifier).to eq :from_node
        expect(wrapper.to_node_identifier).to eq :to_node
        expect(wrapper.rel_identifier).to eq :rel
      end

      it 'can be redefined' do
        expect { wrapper.from_node_identifier = :from }.to change { wrapper.from_node_identifier }.to :from
        expect { wrapper.to_node_identifier = :to }.to change { wrapper.to_node_identifier }.to :to
        expect { wrapper.rel_identifier = :rel_id }.to change { wrapper.rel_identifier }.to :rel_id
      end
    end

    describe '#persisted?' do
      it { expect(wrapper.persisted?).to eq false }
    end

    describe 'properties' do
      let(:new_props) { {foo: :bar} }

      it 'can be reset' do
        expect { wrapper.properties = new_props }.to change { wrapper.properties }.to(new_props)
      end
    end

    describe '#props_for_create' do
      before { wrapper.properties = props }

      it 'returns the current properties' do
        expect(wrapper.props_for_create).to eq props
      end
    end

    describe '#create_method' do
      it 'defaults to :create' do
        expect(wrapper.create_method).to eq :create
      end

      it 'changes through #creates_unique' do
        expect do
          expect { wrapper.creates_unique(:none) }.to change { wrapper.create_method }.from(:create).to(:create_unique)
        end.to change { wrapper.creates_unique? }.from(false).to(true)

        expect do
          expect { wrapper.creates_unique(false) }.to change { wrapper.create_method }.from(:create_unique).to(:create)
        end.to change { wrapper.creates_unique? }.from(true).to(false)
      end
    end

    describe '#creates_unique_options' do
      let(:unique_props) { {unique: {on: [:foo, :bar, :baz]}} }
      it 'corresponds with the setting on the association' do
        expect(wrapper.creates_unique_option).to eq unique_props[:unique]
      end
    end
  end
end
