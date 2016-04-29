describe Neo4j::ActiveNode do
  before(:each) do
    stub_active_node_class('Person') do
      property :name
    end
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

  # moved from unit/active_node/persistence_spec.rb
  describe 'save' do
    it 'creates a new node if not persisted before' do
      delete_db

      p = Person.new
      expect(Person.count).to eq(0)
      p.save
      expect(Person.count).to eq(1)
      expect(Person.first.neo_id).to eq(p.neo_id)
    end

    it 'creates a new node if started as unpersisted' do
      p = nil
      expect_queries(0) do
        p = Person.new(name: 'Francis')
      end
      expect_queries(1) { p.save }
      expect_queries(0) { p.save }
      p.name = 'Deadpool'
      expect_queries(1) { p.save }
    end

    it "doesn't make the query if nothing changed" do
      p = nil
      expect_queries(1) do
        p = Person.create(name: 'Francis')
      end
      expect_queries(0) { p.save }
      p.name = 'Deadpool'
      expect_queries(1) { p.save }
      expect_queries(0) { p.save }
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
