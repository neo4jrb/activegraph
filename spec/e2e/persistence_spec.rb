describe Neo4j::ActiveNode do
  before(:each) do
    stub_active_node_class('Person') do
      property :name, type: String
      property :age, type: Integer
    end

    stub_active_node_class('WithValidations') do
      property :name

      validates :name, presence: true
    end
  end

  def get_value_from_db(node, prop)
    node.class.where(id: node.id).pluck(prop).first
  end

  describe '.new' do
    it 'does not allow setting undeclared properties' do
      expect(Person.new(name: 'Jim').props).to eq(name: 'Jim')
    end

    it 'undefined properties are found with the attributes method' do
      expect(Person.new(name: 'Jim').attributes).to eq('name' => 'Jim', 'age' => nil)
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

  describe '.create' do
    it 'does not store nil values' do
      person = Person.create(name: 'Jim', age: nil)
      expect(person.props).to eq(name: 'Jim')
    end

    it 'stores undefined attributes' do
      person = Person.create(name: 'Jim')
      expect(person.attributes).to eq('name' => 'Jim', 'age' => nil)
    end

    it 'does not allow to set undeclared properties using create' do
      expect { Person.create(foo: 43) }.to raise_error Neo4j::Shared::Property::UndefinedPropertyError
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
      p.name = 'Wade Winston Wilson'
      expect_queries(1) { p.save }
    end

    it "doesn't make the query if noperson changed" do
      p = nil
      expect_queries(1) do
        p = Person.create(name: 'Francis')
      end
      expect_queries(0) { p.save }
      p.name = 'Wade Winston Wilson'
      expect_queries(1) { p.save }
      expect_queries(0) { p.save }
    end

    it 'saves declared the properties that has been changed with []= operator' do
      person = Person.new
      person[:name] = 'Jim'
      person.save
      expect(person.name).to eq('Jim')
      expect(get_value_from_db(person, :name)).to eq('Jim')
    end

    it 'raise Neo4j::Shared::UnknownAttributeError if trying to set undeclared property' do
      expect { Person.new[:foo] = 42 }.to raise_error(Neo4j::UnknownAttributeError)
    end
  end

  describe '#save!' do
    it 'returns true on success' do
      person = Person.new
      person[:name] = 'Jim'
      expect(person.save!).to be true
    end

    context 'with validations' do
      it 'raises an error with invalid params' do
        with_validations = WithValidations.new
        expect { with_validations.save! }.to raise_error(Neo4j::ActiveNode::Persistence::RecordInvalidError)
      end
    end
  end

  describe 'update_attribute' do
    let(:person) do
      WithValidations.create(name: 'Jim')
    end

    it 'updates given property' do
      person.update_attribute(:name, 'Joe')
      expect(get_value_from_db(person, :name)).to eq('Joe')
    end

    it 'does not update it if it is not valid' do
      expect(person.update_attribute(:name, nil)).to be false
      expect(get_value_from_db(person, :name)).to eq('Jim')
    end
  end

  describe 'update_attribute!' do
    let(:person) do
      WithValidations.create(name: 'Jim')
    end

    it 'updates given property' do
      person.update_attribute!(:name, 'Joe')
      expect(get_value_from_db(person, :name)).to eq('Joe')
    end

    it 'does not update it if it is not valid' do
      expect do
        person.update_attribute!(:name, nil)
      end.to raise_error(Neo4j::ActiveNode::Persistence::RecordInvalidError)

      expect(get_value_from_db(person, :name)).to eq('Jim')
    end
  end

  describe 'update_attribute' do
    let(:person) do
      WithValidations.create(name: 'Jim')
    end

    it 'updates given property' do
      person.update_attributes(name: 'Joe')
      expect(get_value_from_db(person, :name)).to eq('Joe')
    end

    it 'does not update it if it is not valid' do
      expect(person.update_attributes(name: nil)).to be false
      expect(get_value_from_db(person, :name)).to eq('Jim')
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
