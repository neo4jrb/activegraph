describe Neo4j::ActiveNode do
  before(:each) do
    stub_active_node_class('Person')
  end

  describe '#persisted?' do
    it 'returns false for new objects' do
      o = Person.new
      expect(o.persisted?).to eq(false)
    end

    it 'returns true for created objects' do
      o = Person.create
      expect(o.persisted?).to eq(true)
    end

    it 'returns false for destroyed objects' do
      o = Person.create
      o.destroy
      expect(o.persisted?).to eq(false)
    end
  end

  describe 'associations and mass-assignment' do
    before do
      stub_active_node_class('MyModel') do
        validates_presence_of :friend

        has_one :out, :friend, type: :FRIENDS_WITH, model_class: :FriendModel
      end

      stub_active_node_class('FriendModel')
    end

    describe 'class method #create!' do
      context 'association validation fails' do
        it 'raises an error' do
          expect { MyModel.create! }.to raise_error Neo4j::ActiveNode::Persistence::RecordInvalidError, "Friend can't be blank"
        end

        it 'does not create the rel' do
          expect { MyModel.create }.not_to change { MyModel.count }
        end
      end

      context 'association validation succeeds' do
        it 'creates the node and relationship' do
          expect do
            MyModel.create!(friend: FriendModel.create!)
          end.to change { MyModel.as(:m).friend(:f, :r).pluck('count(m), count(r), count(f)').flatten.inject(&:+) }.by(3)
        end
      end
    end

    describe 'instance #save!' do
      context 'association validation fails' do
        it 'raises an error' do
          expect { MyModel.new.save! }.to raise_error Neo4j::ActiveNode::Persistence::RecordInvalidError, "Friend can't be blank"
        end
      end

      context 'association validation succeeds' do
        it 'creates the node and relationship' do
          expect do
            MyModel.new(friend: FriendModel.create).save!
          end.to change { MyModel.as(:m).friend(:f, :r).pluck('count(m), count(r), count(f)').flatten.inject(&:+) }.by(3)
        end
      end
    end
  end
end

describe Neo4j::ActiveRel do
  before do
    stub_active_node_class('Person') do
      property :name
    end
    stub_active_rel_class('FriendsWith') do
      from_class false
      to_class false
      property :level
    end
  end

  let(:rel) { FriendsWith.create(Person.new(name: 'Chris'), Person.new(name: 'Lauren'), level: 1) }

  it 'reloads' do
    expect(rel.level).to eq 1
    rel.level = 0
    expect { rel.reload }.to change { rel.level }.from(0).to(1)
  end
end
