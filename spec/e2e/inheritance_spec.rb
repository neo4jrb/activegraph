describe 'Inheritance', type: :e2e do
  before(:each) do
    clear_model_memory_caches

    stub_active_node_class('Node') do
      property :created_at, type: DateTime
      property :updated_at, type: DateTime
      property :foo, type: String, default: 'foo'
    end

    create_index :Vehicle, :name, type: :exact
    stub_named_class('Vehicle', Node) do
      property :name, type: String
      property :specs # Hash
      serialize :specs
      has_many :out, :models, type: nil, model_class: false
    end

    create_index :Car, :model, type: :exact
    stub_named_class('Car', Vehicle) do
      property :model
    end

    stub_active_rel_class('BaseRel') do
      from_class false
      to_class false
      property :foo, type: String, default: 'foo'
    end

    stub_named_class('ManufacturedBy', BaseRel) do
      property :on, type: DateTime
    end
  end

  before(:each) do
    [Car, Vehicle].each(&:delete_all)
    @bike = Vehicle.create(name: 'bike')
    @volvo = Car.create(name: 'volvo', model: 'v60')
    @saab = Car.create(name: 'saab', model: '900')
  end

  describe 'ActiveNode' do
    describe 'find' do
      it 'can find using subclass index' do
        expect(@volvo.labels).to match_array([:Car, :Node, :Vehicle])
        expect(Car.where(name: 'volvo').first).to eq(@volvo)
        expect(Vehicle.where(name: 'volvo').first).to eq(@volvo)
      end

      it 'can find using baseclass index' do
        expect(@saab.labels).to match_array([:Car, :Node, :Vehicle])
        expect(Car.where(model: '900').first).to eq(@saab)
        expect(Vehicle.where(model: '900').first).to eq(@saab)
      end
    end

    describe 'all' do
      it 'can find all sub and base classes' do
        expect(Vehicle.all.to_a).to match_array([@saab, @bike, @volvo])
        expect(Car.all.to_a).to match_array([@saab, @volvo])
      end
    end

    describe 'properties' do
      it 'inherits' do
        expect(Car.new.foo).to eq 'foo'
      end
    end
  end

  describe 'ActiveRel' do
    let(:rel) { ManufacturedBy.new }

    it 'inherits properties' do
      expect(rel.foo).to eq 'foo'
    end
  end

  describe 'serialization' do
    let!(:toyota) do
      Car.create(name: 'toyota', model: 'camry')
    end

    it 'successfully saves and returns hashes from the base class' do
      specs = {weight: 3000, doors: 4}
      toyota.specs = specs
      toyota.save
      expect(toyota.specs).to eq specs
      expect(toyota.specs.class).to eq Hash
    end
  end

  describe 'associations' do
    it 'are inherited' do
      expect(Car.new).to respond_to(:models)
      expect(Vehicle.associations_keys).to include(:models)
      expect(Car.associations_keys).to include(:models)
    end
  end

  describe 'property declared on parent after inheritence' do
    before(:each) do
      stub_named_class('MiniCooper', Car) do
        property :cost
      end

      Car.property :technical_specs
      Car.serialize :technical_specs
      Car.enum doors: [:four_door, :two_door], _index: false
    end

    let(:mini) { MiniCooper.new }

    it 'child inherites setters' do
      expect(mini.technical_specs = {very: 'technical'}).to eq(very: 'technical')
      expect(mini.doors = :four_door).to eq(:four_door)
    end

    it 'child inherites getters' do
      mini.technical_specs = {very: 'technical'}
      mini.doors = :four_door

      expect(mini.technical_specs).to eq(very: 'technical')
      expect(mini.doors).to eq(:four_door)
    end

    it 'persists values' do
      mini.technical_specs = {very: 'technical'}
      mini.doors = :four_door
      mini.save!

      expect(MiniCooper.first.doors).to eq(:four_door)
      expect(MiniCooper.first.technical_specs).to eq('very' => 'technical')
    end
  end
end
