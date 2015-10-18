require 'spec_helper'


# class ExtendedIceLolly < IceLolly
#  property :extended_property
# end

describe 'Neo4j::ActiveNode' do
  before(:each) do
    clear_model_memory_caches
    delete_db

    stub_active_node_class('IceLolly') do
      property :flavour
      property :name
      property :a
      property :b
      property :required_on_create
      property :required_on_update
      property :created
      property :start, type: Time

      property :created_at
      property :updated_at

      attr_reader :saved

      index :flavour

      validates :flavour, presence: true
      validates :required_on_create, presence: true, on: :create
      validates :required_on_update, presence: true, on: :update

      before_create :timestamp
      after_create :mark_saved

      protected

      def timestamp
        self.created = 'yep'
      end

      def mark_saved
        @saved = true
      end
    end

    stub_active_node_class('IceCream') do
      property :flavour, index: :exact
      # has_n(:ingredients).to(Ingredient)
      validates_presence_of :flavour
    end
  end

  subject { IceLolly.new }

  context 'when valid' do
    before :each do
      subject.flavour = 'vanilla'
      subject.required_on_create = 'true'
      subject.required_on_update = 'true'
    end

    it_should_behave_like 'new model'
    it_should_behave_like 'loadable model'
    it_should_behave_like 'saveable model'
    it_should_behave_like 'creatable model'
    it_should_behave_like 'destroyable model'
    it_should_behave_like 'updatable model'
    it_should_behave_like 'timestamped model'

    context 'after being saved' do
      before do
        subject.class.delete_all
        subject.save
      end

      # it { subject.id.should eq(subject.class.find(flavour: 'vanilla').id)}

      it { should eq(subject.class.where(flavour: 'vanilla').first) }

      it 'should be able to modify one of its named attributes' do
        lambda { subject.update_attributes!(flavour: 'horse') }.should_not raise_error
        subject.flavour.should eq('horse')
      end

      it 'should not have the extended property' do
        subject.attributes.should_not include('extended_property')
      end

      it 'should respond to class.all' do
        subject.class.respond_to?(:all)
      end

      it "should respond to class#all(:flavour => 'vanilla')" do
        subject.class.where(flavour: 'vanilla').should include(subject)
      end

      context 'and then made invalid' do
        before { subject.required_on_update = nil }

        it "shouldn't be updatable" do
          subject.update_attributes(flavour: 'fish').should_not be true
        end

        it 'should have the same attribute values after an unsuccessful update and reload' do
          subject.update_attributes(flavour: 'fish')
          subject.reload.flavour.should eq('vanilla')
          subject.required_on_update.should_not be_nil
        end
      end
    end

    context 'after create' do
      before :each do
        @obj = subject.class.create!(subject.attributes)
      end

      it 'should have run the #timestamp callback' do
        @obj.created.should_not be_nil
      end

      it 'should have run the #mark_saved callback' do
        @obj.saved.should_not be_nil
      end
    end
  end

  context 'when invalid' do
    it_should_behave_like 'new model'
    it_should_behave_like 'unsaveable model'
    it_should_behave_like 'uncreatable model'
    it_should_behave_like 'non-updatable model'
  end

  describe 'validations' do
    it 'does not have any errors if its valid' do
      ice_cream = IceCream.new(flavour: 'strawberry')
      ice_cream.should be_valid
      ice_cream.errors.should be_empty
    end

    it 'does have errors if its not valid' do
      ice_cream = IceCream.new
      ice_cream.should_not be_valid
      ice_cream.errors.should_not be_empty
    end

    context 'a model with a case sensitive uniqueness validation' do
      before do
        stub_active_node_class('Uniqueness') do
          property :unique_property, type: String, constraint: :unique
          validates :unique_property, uniqueness: {case_sensitive: false}
        end
      end

      it 'gives an error if not unique' do
        Uniqueness.create(unique_property: 'test')

        object = Uniqueness.create(unique_property: 'test')
        expect(object).to have_error_on(:unique_property)

        object = Uniqueness.create(unique_property: 'Test')
        expect(object).to have_error_on(:unique_property)
      end
    end
  end

  describe 'global timestamps config' do
    context 'default' do
      before do
        stub_active_node_class('NoTimestampsClass')
        stub_active_node_class('ClassWithTimestampsIncluded') do
          include Neo4j::Timestamps
        end
      end

      it 'does not include timestamp properites on all models' do
        node = NoTimestampsClass.new
        expect(node).not_to be_a(Neo4j::Timestamps)
      end

      it 'allows timestamps to be manually included' do
        node = ClassWithTimestampsIncluded.new
        expect(node).to be_a(Neo4j::Timestamps)
      end
    end

    context 'when record_timestamps is enabled' do
      let_config(:record_timestamps) { true }

      before do
        stub_active_node_class('TimestampedClass')
      end

      it 'includes timestamp properties on all models' do
        node = TimestampedClass.new
        expect(node).to be_a(Neo4j::Timestamps)
      end
    end
  end

  describe 'callbacks' do
    before(:each) do
      stub_active_node_class('Company') do
        attr_accessor :update_called, :save_called, :destroy_called, :validation_called
        property :name

        before_save do
          @save_called = true
        end

        before_update do
          @update_called = true
        end

        before_destroy do
          @destroy_called = true
        end

        before_validation do
          @validation_called = true
        end
      end
    end

    it 'handles before_save callbacks' do
      c = Company.new
      c.save_called.should be_nil
      c.save
      c.save_called.should be true
    end

    it 'handles before_update callbacks' do
      c = Company.create
      c.update(name: 'foo')
      expect(c.update_called).to be true
    end

    it 'handles before_destroy callbacks' do
      c = Company.create
      c.destroy
      expect(c.destroy_called).to be true
    end

    it 'handles before_validation callbacks' do
      #      skip
      c = Company.create
      expect(c.validation_called).to be true
    end

    context 'that raise errors' do
      before do
        [:create, :update, :destroy].each { |m| Company.reset_callbacks(m) }
      end

      it 'rolls back node creation' do
        starting_count = Company.count
        expect { Company.create }.not_to raise_error
        expect(Company.count).not_to eq starting_count
        starting_count += 1

        Company.after_create { fail }
        expect { Company.create }.to raise_error
        expect(Company.count).to eq starting_count
      end

      it 'rolls back node update' do
        c = Company.create(name: 'Daylight Dies')
        expect(c.name).to eq 'Daylight Dies'
        c.name = 'Katatonia'
        expect { c.save }.not_to raise_error
        expect(c.name).to eq 'Katatonia'
        Company.after_update { fail }

        c.name = 'October Tide'
        expect { c.save }.to raise_error
        c.reload
        expect(c.name).to eq 'Katatonia'
      end

      it 'rolls back node destroy' do
        c = Company.create(name: 'Foo')
        expect(c).to be_persisted
        expect { c.destroy }.not_to raise_error
        expect(c).not_to be_persisted
        Company.after_destroy { fail }
        c = Company.create(name: 'Foo')
        expect { c.destroy }.to raise_error
        expect(c).to be_persisted
        expect(c).not_to be_frozen
        expect(c).not_to be_changed
      end
    end
  end

  describe 'cached classnames' do
    after(:all) { Neo4j::Config[:cache_class_names] = true }
    before do
      stub_const('CacheTest', UniqueClass.create do
        include Neo4j::ActiveNode
      end)
    end

    context 'with cache_class set in config' do
      before { Neo4j::Session.current.class.any_instance.stub(version: db_version) }

      before do
        Neo4j::Config[:cache_class_names] = true
        @cached = CacheTest.create
        @unwrapped = Neo4j::Node._load(@cached.neo_id)
      end

      context 'server version 2.1.4' do
        let(:db_version) { '2.1.4' }

        it 'responds true to :cached_class?' do
          expect(CacheTest.cached_class?).to be_truthy
        end

        it 'sets _classname property equal to class name' do
          expect(@unwrapped[:_classname]).to eq @cached.class.name
        end

        it 'removes the _classname property from the wrapped class' do
          expect(@cached.props).to_not have_key(:_classname)
        end
      end

      context 'server version 2.1.5' do
        let(:db_version) { '2.1.5' }

        it 'responds false to :cached_class?' do
          expect(CacheTest.cached_class?).to be_falsey
        end

        it 'does not set _classname' do
          expect(@unwrapped[:_classname]).to be_nil
        end

        it 'removes the _classname property from the wrapped class' do
          expect(@cached.props).to_not have_key(:_classname)
        end
      end
    end

    context 'without cache_class set in model' do
      before do
        Neo4j::Config[:cache_class_names] = false
        @uncached = CacheTest.create
        @unwrapped = Neo4j::Node._load(@uncached.neo_id)
      end

      before { Neo4j::Config[:cache_class_names] = false }

      it 'response false to :cached_class?' do
        expect(CacheTest.cached_class?).to be_falsey
      end

      it 'does not set _classname on the node' do
        expect(@unwrapped.props).to_not have_key(:_classname)
      end
    end
  end

  before(:each) do
    stub_active_node_class('Person') do
      property :name
      property :age,          type: Integer
      property :start,        type: Time
      property :links
      property :datetime,     type: DateTime
      property :date,         type: Date
      property :numbers

      serialize :links
      # Need this validation for create!
      validates_presence_of :name
    end
  end

  describe 'basic persistence' do
    it 'generate accessors for declared attribute' do
      person = Person.new(name: 'hej')
      expect(person.name).to eq('hej')
      person.name = 'new name'
      expect(person.name).to eq('new name')
    end

    it 'accepts Time type, does not convert to DateTime' do
      person = Person.create(start: Time.now)
      expect(person.start).to be_a(Time)
    end

    it 'declared attribute can have type conversion' do
      person = Person.create(age: '40')
      expect(person.age).to eq(40)
      person.age = '42'
      person.save
      expect(person.age).to eq(42)
    end

    it 'attributes and [] accessors can be combined' do
      person = Person.create(age: '40')
      expect(person.age).to eq(40)
      expect(person[:age]).to eq(40)
      expect(person['age']).to eq(40)
      person[:age] = '41'
      expect(person.age).to eq(41)

      expect(person['age']).to eq(41)
      expect(person[:age]).to eq(41)
    end

    it 'can persist a new object' do
      person = Person.new(name: 'John')
      person.neo_id.should be_nil
      person.save
      person.neo_id.should be_a(Integer)
      person.exist?.should be true
    end

    it 'can set properties' do
      person = Person.new(name: 'andreas', age: 21)
      person[:name].should eq('andreas')
      person[:age].should eq(21)
      person.save
      person[:name].should eq('andreas')
      person[:age].should eq(21)
    end

    it 'can create the node' do
      person = Person.create(name: 'andreas', age: 21)
      person.neo_id.should be_a(Integer)
      person[:name].should eq('andreas')
      person[:age].should eq(21)
      person.exist?.should be true
    end

    # Escaping strings is handled by neo4j-core but more tests never hurt.
    # If this fails, it likely suggests a problem in that gem.
    it 'can save properties with apostrophes' do
      person = Person.create(name: "D'Amore-Schamberger")
      person.reload
      expect(person).to be_persisted
      expect(person.name).to eq "D'Amore-Schamberger"
    end

    it 'can find or create by...' do
      expect(Person.find_by(name: 'Donovan', age: 30)).to be_falsey
      expect { Person.find_or_create_by(name: 'Donovan', age: 30) }.to change { Person.count }
      expect(Person.find_by(name: 'Donovan', age: 30)).not_to be_falsey
    end

    it 'can find or create by... AGGRESSIVELY' do
      expect(Person.find_by(name: 'Darcy', age: 5)).to be_falsey
      expect { Person.find_or_create_by!(name: 'Darcy', age: 30) }.to change { Person.count }
      expect { Person.find_or_create_by!(name: nil) }.to raise_error
    end

    # This also works for create! and find_by_or_create/find_by_or_create!
    it 'can create using a block' do
      person = Person.create do |p|
        p.name = 'Wilson'
        p.age = 50
      end
      expect(person.persisted?).to be_truthy
      expect(person.name).to eq 'Wilson'
    end

    it 'can be deleted' do
      person = Person.create(name: 'andreas', age: 21)
      person.destroy
      person.persisted?.should be false
    end

    it 'can be loaded by id' do
      person1 = Person.create(name: 'andreas', age: 21)
      person2 = Neo4j::Node.load(person1.neo_id)
      person2.neo_id.should eq(person1.neo_id)
      person2.neo_id.should eq(person1.neo_id)
    end

    it 'does not persist updated properties until they are saved' do
      person = Person.create(name: 'andreas', age: 21)
      person[:age] = 22

      person2 = Neo4j::Node.load(person.neo_id)
      person2[:age].should eq(21)
    end

    it 'should not clear out existing properties when property is set and saved' do
      person = Person.create(name: 'andreas', age: 21)
      person.age = 22
      person.save
      person2 = Neo4j::Node.load(person.neo_id)
      person2.age.should eq(22)
      person2.name.should eq('andreas')
    end

    it 'they can be all found' do
      person1 = Person.create(name: 'person1', age: 21)
      person2 = Person.create(name: 'person2', age: 21)
      Person.all.should include(person1, person2)
    end

    it 'they can be queries' do
      Person.create(name: 'person3', age: 21)
      person2 = Person.create(name: 'person4', age: 21)
      Person.where(name: 'person4').to_a.map(&:neo_id).should eq([person2.neo_id])
    end

    it 'saves all declared properties' do
      expect do
        Person.create(name: 'person123', age: 123, unknown: 'yes')
      end.to raise_error(Neo4j::Shared::Property::UndefinedPropertyError)
    end

    it 'does not have the weird bug described in issue #761' do
      stub_active_node_class('Community') do
        property :name
      end

      stub_active_node_class('School') do
        property :name
        has_many :out, :child_of, type: :child_of, model_class: 'Community'
      end

      ivy_league = Community.create(name: 'Ivy League')

      %w( Yale Harvard Cornell ).each do |name|
        School.create(name: name, child_of: [ivy_league])
      end

      School.create(name: 'The College of New Jersey')

      expect(School.where(name: 'The College of New Jersey').child_of.to_a).to be_empty
    end

    describe 'default property values' do
      before { Person.property(:default_prop, default: 'Chopper') }
      let(:guy) { Person.create(name: 'Guy Foo') }

      it 'sets the default value if nil on persistence' do
        expect(guy.default_prop).to eq 'Chopper'
      end
    end

    describe 'multiparameter attributes' do
      it 'converts to Date' do
        person = Person.create('date(1i)' => '2014', 'date(2i)' => '7', 'date(3i)' => '13')
        expect(person.date).to be_a Date
        expect(person.date.to_s).to eq '2014-07-13'
      end

      it 'converts to DateTime' do
        person = Person.create('datetime(1i)' => '2014', 'datetime(2i)' => '7', 'datetime(3i)' => '13', 'datetime(4i)' => '17', 'datetime(5i)' => '45')
        expect(person.datetime).to be_a DateTime
        expect(person.datetime).to eq 'Sun, 13 Jul 2014 17:45:00 +0000'
      end

      it 'raises an error when it receives values it cannot process' do
        expect do
          Person.create('foo(1i)' => '2014', 'foo(2i)' => '2014')
        end.to raise_error(Neo4j::Shared::Property::MultiparameterAssignmentError)
      end

      it 'sends values straight through when no type is specified' do
        person = Person.create('numbers(1i)' => '5', 'numbers(2i)' => '23')
        expect(person.numbers).to be_a Array
        expect(person.numbers).to eq [5, 23]
      end

      it 'leaves standard attributes alone' do
        person = Person.create('date(1i)' => '2014', 'date(2i)' => '7', 'date(3i)' => '13', name: 'chris')
        expect(person.name).to eq 'chris'
        expect(person.date).to be_a Date
      end

      it 'converts on update in addition to create' do
        person = Person.create
        person.update_attributes('date(1i)' => '2014', 'date(2i)' => '7', 'date(3i)' => '13')
        person.save
        expect(person.date).to be_a Date
        expect(person.date.to_s).to eq '2014-07-13'
      end
    end
  end

  describe 'serialization' do
    let!(:chris) { Person.create(name: 'chris') }
    let(:links) { {'neo4j' => 'http://www.neo4j.org', 'neotech' => 'http://www.neotechnology.com/'} }

    it 'correctly identifies properties for serialization' do
      expect(Person.serialized_properties).to include(:links)
      expect(chris.serialized_properties).to include(:links)
    end

    it 'successfully saves and returns hashes' do
      chris.links = links
      chris.save
      expect(chris.links).to eq links
      expect { chris.reload }.not_to change { chris.links }
    end

    describe 'QueryProxy #where' do
      before do
        chris.links = links
        chris.save
      end

      it 'serializes values given to #where' do
        expect(Person.where(links: links).first.links).to eq links
      end
    end
  end

  describe 'DateTime' do
    before(:each) { Person.delete_all }

    let(:datetime) { Time.new(2015, 1, 2, 3, 4, 5, '+06:00') }
    let!(:person) { Person.create(name: 'DateTime', datetime: datetime) }

    let(:datetime_db_value) do
      Neo4j::Session.query.match(p: :Person)
        .where(p: {neo_id: person.neo_id})
        .pluck(p: :datetime).first
    end

    it 'saves as date/time string by default' do
      expect(datetime_db_value).to eq(1_420_146_245)
    end
  end

  describe 'cache_key' do
    describe 'unpersisted object' do
      it 'should respond with plural_model/new' do
        model = IceLolly.new
        model.cache_key.should eq "#{model.class.model_name.cache_key}/new"
      end
    end

    describe 'persisted object' do
      let(:model) { IceLolly.create(flavour: 'vanilla', required_on_create: true, required_on_update: true) }

      it 'should respond with a valid cache key' do
        expect(model.cache_key).to eq "#{model.class.model_name.cache_key}/#{model.neo_id}-#{model.updated_at.utc.to_s(:number)}"
      end

      context 'when changed' do
        it 'should change cache_key value' do
          start = model.cache_key && sleep(1)
          model.flavour = 'chocolate' && model.save
          expect(model.cache_key).to_not eq start
        end
      end

      describe 'without updated_at property' do
        before do
          stub_const('NoStamp', UniqueClass.create do
            include Neo4j::ActiveNode
            property :name
          end)
        end

        let(:nostamp) { NoStamp.create }
        it 'returns cache key without timestamp' do
          expect(nostamp.cache_key).to eq "#{nostamp.class.model_name.cache_key}/#{nostamp.neo_id}"
        end
      end
    end
  end

  describe 'method chaining' do
    before(:each) do
      stub_active_node_class('Cat') do
        property :name

        def self.named_bill
          all(:random_var).where("random_var.name = 'Bill'").pluck(:random_var)
        end

        def self.named_jim
          all.where(name: 'Jim')
        end
      end
    end
    context 'A Bill' do
      let!(:bill) { Cat.create(name: 'Bill') }
      context 'A Jim' do
        let!(:jim) { Cat.create(name: 'Jim') }

        context 'Cat has a .named_bill scoping method' do
          it 'only returns Bill' do
            expect(Cat.named_bill.to_a).to eq([bill])
            expect(Cat.all.named_bill.to_a).to eq([bill])
            expect(Cat.all(:another_variable).named_bill.to_a).to eq([bill])
          end

          context 'with an exiting node identity' do
            it 'reuses or resets' do
              expect(Cat.as(:c).named_jim.pluck(:c)).to eq([jim])
              expect(Cat.as(:c).all.named_jim.pluck(:c)).to eq([jim])
              expect { Cat.as(:c).all(:another_variable).named_jim.pluck(:c) }.to raise_error
              expect(Cat.as(:c).all(:another_variable).named_jim.pluck(:another_variable)).to eq [jim]
            end
          end
        end
      end
    end
  end

  describe 'Neo4j::Paginated.create_from' do
    before do
      Person.delete_all
      i = 1.upto(16).to_a
      i.each { |count| Person.create(name: "Billy-#{i}", age: count) }
    end

    let(:t) { Person.where }
    let(:p) { Neo4j::Paginated.create_from(t, 2, 5) }

    it 'returns a Neo4j::Paginated' do
      expect(p).to be_a(Neo4j::Paginated)
    end

    it 'returns the expected number of objects' do
      expect(p.count).to eq 5
    end

    describe 'ordered pagination' do
      before do
        Person.delete_all
        %w(Alice Bob Carol David).each { |name| Person.create(name: name) }
      end

      it 'allows ordering with a symbol' do
        person = Neo4j::Paginated.create_from(Person.all, 1, 2, :name)
        expect(person.count).to eq 2
        expect(person.first.name).to eq 'Alice'
      end

      it 'allows ordering with a hash' do
        person = Neo4j::Paginated.create_from(Person.all, 1, 2, name: :desc)
        expect(person.count).to eq 2
        expect(person.first.name).to eq 'David'
      end
    end
  end

  describe 'finding by id_property' do
    let(:activenode_class) { active_node_class('TestClass') }
    let(:object) { activenode_class.create }

    describe 'where' do
      it 'should use uuid' do
        expect(activenode_class.where(id: object).first).to eq(object)
        expect(activenode_class.where(id: object.id).first).to eq(object)
        expect(activenode_class.where(id: object.uuid).first).to eq(object)
      end

      context 'different id_property is specified' do
        let(:activenode_class) do
          active_node_class('TestClass') do
            id_property :foo
          end

          it 'should use uuid' do
            expect(activenode_class.where(id: object).first).to eq(object)
            expect(activenode_class.where(id: object.id).first).to eq(object)
            expect(activenode_class.where(id: object.foo).first).to eq(object)
          end
        end
      end
    end

    describe 'find_by' do
      it 'should use uuid' do
        expect(activenode_class.find_by(id: object)).to eq(object)
        expect(activenode_class.find_by(id: object.id)).to eq(object)
        expect(activenode_class.find_by(id: object.uuid)).to eq(object)
      end

      context 'different id_property is specified' do
        let(:activenode_class) do
          active_node_class('TestClass') do
            id_property :foo
          end

          it 'should use uuid' do
            expect(activenode_class.find_by(id: object)).to eq(object)
            expect(activenode_class.find_by(id: object.id)).to eq(object)
            expect(activenode_class.find_by(id: object.foo)).to eq(object)
          end
        end
      end
    end
  end

  # TODO: Rewrite/move into unit tests once master is merged into 5.1.x.
  describe 'model reloading' do
    before { stub_active_node_class('MyModel') }

    describe 'before_remove_const' do
      it 'populates the MODELS_TO_RELOAD set' do
        expect { MyModel.before_remove_const }.to change { Neo4j::ActiveNode::Labels::Reloading::MODELS_TO_RELOAD.count }
      end
    end

    describe 'reload_models!' do
      let!(:reload_cache) { Neo4j::ActiveNode::Labels::Reloading::MODELS_TO_RELOAD }
      before { MyModel.before_remove_const }
      it 'constantizes the models and clears list of models to reload' do
        expect(reload_cache).to receive(:each)
        expect(reload_cache).to receive(:clear)
        Neo4j::ActiveNode::Labels::Reloading.reload_models!
      end
    end
  end
end
