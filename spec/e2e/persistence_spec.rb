describe ActiveGraph::Node do
  before(:each) do
    stub_node_class('Person') do
      property :name, type: String
      property :age, type: Integer
    end

    stub_node_class('WithValidations') do
      attr_accessor :callback_fired

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
      expect { Person.create(foo: 43) }.to raise_error ActiveGraph::Shared::Property::UndefinedPropertyError
    end
  end

  # moved from unit/node/persistence_spec.rb
  describe 'save' do
    it 'creates a new node if not persisted before' do
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

    it 'raise ActiveGraph::Shared::UnknownAttributeError if trying to set undeclared property' do
      expect { Person.new[:foo] = 42 }.to raise_error(ActiveGraph::UnknownAttributeError)
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
        expect { with_validations.save! }.to raise_error(ActiveGraph::Node::Persistence::RecordInvalidError)
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
      end.to raise_error(ActiveGraph::Node::Persistence::RecordInvalidError)

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

  describe '#update_db_propert(y|ies)' do
    before do
      stub_node_class('UpdateWithValidations') do
        attr_accessor :callback_fired

        property :name
        property :updated_at
        property :age, type: Integer
        after_update -> { self.callback_fired = true }

        validates :name, presence: true
        validates :age, inclusion: {in: [21]}
      end
    end

    let!(:person) { UpdateWithValidations.create!(name: 'Jim', age: 21) }

    shared_examples_for 'an update using update_db_propert(y|ies)' do
      it 'updates the value in the database without validating' do
        expect { update! }.to change { UpdateWithValidations.find(person).age }.from(21).to(20)
      end

      it 'updates the value on instance' do
        expect { update! }.to change { person.age }.from(21).to(20)
      end

      it 'does not flag the field as dirty' do
        expect { update! }.not_to change { person.age_changed? }.from(false)
      end

      it 'does not update timestamps' do
        Timecop.travel(Time.now + 3600) do
          expect { update! }.not_to change { UpdateWithValidations.find(person).updated_at }
        end
      end

      it 'does not trigger callbacks' do
        expect { update! }.not_to change { person.callback_fired }.from(nil)
        expect { person.update(age: 21) }.to change { person.callback_fired }.to(true)
      end

      it 'updates the _persisted_obj' do
        expect { update! }.to change { person._persisted_obj.props[:age] }.to(20)
      end

      it 'returns true' do
        expect(update!).to eq(true)
      end
    end

    describe 'singular `update_db_property`' do
      let(:update!) { person.update_db_property(:age, 20) }
      it_behaves_like 'an update using update_db_propert(y|ies)'

      it 'rejects undeclared values' do
        expect { person.update_db_property(:foo_col, 'foo') }.to raise_error NoMethodError
      end

      it 'performs type conversion' do
        expect do
          person.update_db_property(:age, '20')
        end.not_to change { UpdateWithValidations.find(person).age.is_a?(Numeric) }.from(true)
      end

      context 'on a new record' do
        it do
          expect do
            UpdateWithValidations.new.update_db_property(:age, 20)
          end.to raise_error(ActiveGraph::Error, /can not update on a new record object/)
        end
      end
    end

    describe 'plurual `update_db_properties`' do
      let(:update!) { person.update_db_properties(age: 20) }
      it_behaves_like 'an update using update_db_propert(y|ies)'

      it 'rejects undeclared values' do
        expect { person.update_db_properties(foo_col: 'foo') }.to raise_error NoMethodError
      end

      it 'performs type conversion' do
        expect do
          person.update_db_properties(age: '20')
        end.not_to change { UpdateWithValidations.find(person).age.is_a?(Numeric) }.from(true)
      end

      context 'on a new record' do
        it do
          expect do
            UpdateWithValidations.new.update_db_properties(age: 20)
          end.to raise_error StandardError, /can not update on a new record object/
        end
      end

      context 'when an error occurs in the body of the error' do
        let(:foo_val) { SecureRandom.hex }
        it 'rolls back the database change' do
          expect do
            begin
              person.update_db_properties(foo_val: foo_val)
            rescue; end # rubocop:disable Lint/HandleExceptions
          end.not_to change { UpdateWithValidations.where(foo_val: foo_val).exists? }.from(false)
        end
      end
    end
  end

  describe 'associations and mass-assignment' do
    before do
      stub_node_class('MyModel') do
        validates_presence_of :friend

        has_one :out, :friend, type: :FRIENDS_WITH, model_class: :FriendModel
      end

      stub_node_class('FriendModel')
    end

    describe 'class method #create!' do
      context 'association validation fails' do
        it 'raises an error' do
          expect { MyModel.create! }.to raise_error ActiveGraph::Node::Persistence::RecordInvalidError, "Friend can't be blank"
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
          expect { MyModel.new.save! }.to raise_error ActiveGraph::Node::Persistence::RecordInvalidError, "Friend can't be blank"
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

describe ActiveGraph::Relationship do
  before do
    stub_node_class('Person') do
      property :name
    end
    stub_relationship_class('FriendsWith') do
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
