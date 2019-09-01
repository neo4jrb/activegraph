describe Neo4j::ActiveNode do
  before(:each) do
    stub_active_node_class('Person') do
      include Neo4j::UndeclaredProperties
      property :name, type: String
    end
  end

  def get_value_from_db(node, prop)
    node.class.where(id: node.id).first[prop]
  end

  describe '.new' do
    it 'undeclared properties are found' do
      expect(Person.new(foo: 123)[:foo]).to eq(123)
      expect(Person.new(foo: 123)['foo']).to eq(123)
    end
  end

  describe '.create' do
    it 'does allow to set undeclared properties using create' do
      expect { Person.create(foo: 43) }.not_to raise_error Neo4j::Shared::Property::UndefinedPropertyError
    end

    it 'stores undefined attributes' do
      person = Person.create(name: 'Jim', foo: 123)
      expect(person[:foo]).to eq(123)
      expect(person['foo']).to eq(123)
      expect(get_value_from_db(person, :foo)).to eq(123)
    end
  end

  describe 'save' do
    it 'does not raise Neo4j::Shared::UnknownAttributeError if trying to set undeclared property' do
      expect { Person.new[:foo] = 42 }.not_to raise_error
    end

    it 'saves undeclared the properties that has been changed with []= operator' do
      person = Person.new
      person[:foo] = 123
      person.save
      expect(person[:foo]).to eq(123)
      expect(get_value_from_db(person, :foo)).to eq(123)
    end
  end

  describe '#save!' do
    it 'returns true on success' do
      person = Person.new
      person[:name] = 'Jim'
      person[:foo] = 123
      expect(person.save!).to be true
    end
  end

  describe 'update_attributes' do
    let(:person) do
      Person.create(name: 'Jim', foo: 123)
    end

    it 'updates given declared and udeclared property' do
      person.update_attributes(name: 'Joe', foo: 456)
      expect(get_value_from_db(person, :name)).to eq('Joe')
      expect(get_value_from_db(person, :foo)).to eq(456)
    end

    it 'does delete undeclared property' do
      person.update_attributes(foo: nil)
      expect(get_value_from_db(person, :foo)).to be_nil
    end
  end

  describe 'update_attribute' do
    let(:person) do
      Person.create(name: 'Jim')
    end

    it 'updates given udeclared property' do
      person.update_attribute(:foo, 123)
      expect(get_value_from_db(person, :foo)).to eq(123)
    end

    it 'does delete undeclared property' do
      person.update_attribute(:foo, 123)
      person.update_attribute(:foo, nil)
      expect(get_value_from_db(person, :foo)).to be_nil
    end
  end

  describe 'update_attribute!' do
    let(:person) do
      Person.create(name: 'Jim')
    end

    it 'updates given property' do
      person.update_attribute!(:foo, 123)
      expect(get_value_from_db(person, :foo)).to eq(123)
    end
  end
end
