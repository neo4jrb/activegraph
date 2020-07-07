describe 'ActiveGraph::Node' do
  before(:each) do
    clear_model_memory_caches

    create_index(:IceLolly, :flavour, type: :exact)
    stub_node_class('IceLolly') do
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
      attr_writer :writable_attr

      property :prop_with_default, default: 'something'

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

    create_index(:IceCream, :flavour, type: :exact)
    stub_node_class('IceCream') do
      property :flavour
      # has_n(:ingredients).to(Ingredient)
      validates_presence_of :flavour
    end

    create_index(:IceCandy, :name, type: :exact)
    stub_node_class('IceCandy') do
      property :name, type: String
      property :calories_max, type: Integer
      property :calories_min, type: Integer
      property :suger, type: Float
      property :ingredients, type: Hash
      property :created, type: Time
      property :expiry_date, type: Date
      property :make_date, type: Neo4j::Driver::Types::OffsetTime
      property :storage, type: Neo4j::Driver::Types::Bytes
      property :best_before, type: ActiveSupport::Duration
      property :place, type: Neo4j::Driver::Types::Point
      property :local_time, type: Neo4j::Driver::Types::LocalTime
      property :local_datetime, type: Neo4j::Driver::Types::LocalDateTime
    end
  end

  subject { IceLolly.new }

  context 'Default data types by driver' do
    let(:name) { 'Mango Candy' }
    let(:calories_min) { -9223372036854775809 }
    let(:calories_max) { 9223372036854775809 }
    let(:expiry_date) { Date.today }
    let(:created) { Time.now }
    let(:suger) { Float::MAX }
    let(:ingredients) { { suger: 20, water: 50 } }
    let(:storage) { Neo4j::Driver::Types::Bytes.new([1, 2, 3].pack('C*')) }
    let(:best_before) { 6.months }
    let(:place) { Neo4j::Driver::Types::Point.new(x:10, y:5) }
    let(:make_date) { Neo4j::Driver::Types::OffsetTime.new(Time.now) }
    let(:local_time) { Neo4j::Driver::Types::LocalTime.new(Time.now) }
    let(:local_datetime) { Neo4j::Driver::Types::LocalDateTime.new(Time.now.utc) }

    it 'should support types' do
      IceCandy.create(name: name, calories_min: calories_min, calories_max: calories_max, expiry_date: expiry_date,
                      make_date: make_date, created: created, suger: suger, ingredients: ingredients,
                      storage: storage, best_before: best_before, place: place, local_time: local_time,
                      local_datetime: local_datetime)
      candy = IceCandy.first
      [:name, :calories_min, :calories_max, :expiry_date, :created, :suger, :ingredients, :storage, :best_before,
       :make_date, :local_time, :local_datetime].each do |property|
        expect(candy.send(property)).to eq(eval(property.to_s))
      end
      expect(candy.place).to be_a(Neo4j::Driver::Types::Point)
      expect(candy.place.x).to eq(10)
      expect(candy.place.y).to eq(5)
    end
  end

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

    describe '#new' do
      it 'allows setting of properties via initialize with symbol keys' do
        l = IceLolly.new(prop_with_default: 'something else')
        expect(l.prop_with_default).to eq('something else')
      end

      it 'allows setting of #method= methods via initialize' do
        expect { IceLolly.new(writable_attr: 'test') }.to_not raise_error
      end

      context 'with string keys' do
        it do
          expect(IceLolly.new('prop_with_default' => 'something else').prop_with_default).to eq 'something else'
        end
      end
    end

    context 'after being saved' do
      before do
        subject.class.delete_all
        subject.save
      end

      # it { subject.id.should eq(subject.class.find(flavour: 'vanilla').id)}

      it { is_expected.to eq(subject.class.where(flavour: 'vanilla').first) }

      it 'should be able to modify one of its named attributes' do
        expect { subject.update_attributes!(flavour: 'horse') }.not_to raise_error
        expect(subject.flavour).to eq('horse')
      end

      it 'should not have the extended property' do
        expect(subject.attributes).not_to include('extended_property')
      end

      it 'should respond to class.all' do
        subject.class.respond_to?(:all)
      end

      it "should respond to class#all(:flavour => 'vanilla')" do
        expect(subject.class.where(flavour: 'vanilla')).to include(subject)
      end

      context 'and then made invalid' do
        before { subject.required_on_update = nil }

        it "shouldn't be updatable" do
          expect(subject.update_attributes(flavour: 'fish')).not_to be true
        end

        it 'should have the same attribute values after an unsuccessful update and reload' do
          subject.update_attributes(flavour: 'fish')
          expect(subject.reload.flavour).to eq('vanilla')
          expect(subject.required_on_update).not_to be_nil
        end
      end
    end

    context 'after create' do
      before :each do
        @obj = subject.class.create!(subject.attributes)
      end

      it 'should have run the #timestamp callback' do
        expect(@obj.created).not_to be_nil
      end

      it 'should have run the #mark_saved callback' do
        expect(@obj.saved).not_to be_nil
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
      expect(ice_cream).to be_valid
      expect(ice_cream.errors).to be_empty
    end

    it 'does have errors if its not valid' do
      ice_cream = IceCream.new
      expect(ice_cream).not_to be_valid
      expect(ice_cream.errors).not_to be_empty
    end

    context 'a model with a case sensitive uniqueness validation' do
      before do
        create_constraint(:Uniqueness, :unique_property, type: :unique)
        stub_node_class('Uniqueness') do
          property :unique_property, type: String
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
        stub_node_class('NoTimestampsClass')
        stub_node_class('ClassWithTimestampsIncluded') do
          include ActiveGraph::Timestamps
        end
      end

      it 'does not include timestamp properites on all models' do
        node = NoTimestampsClass.new
        expect(node).not_to be_a(ActiveGraph::Timestamps)
      end

      it 'allows timestamps to be manually included' do
        node = ClassWithTimestampsIncluded.new
        expect(node).to be_a(ActiveGraph::Timestamps)
      end
    end

    context 'when record_timestamps is enabled' do
      let_config(:record_timestamps, true)

      before do
        stub_node_class('TimestampedClass')
      end

      it 'includes timestamp properties on all models' do
        node = TimestampedClass.new
        expect(node).to be_a(ActiveGraph::Timestamps)
      end
    end
  end

  describe 'callbacks' do
    before(:each) do
      stub_node_class('Company') do
        %w(find create save update destroy validation).each do |verb|
          attr_reader :"before_#{verb}_called", :"after_#{verb}_called"
        end

        attr_reader :after_find_called, :after_initialize_called

        property :name

        after_initialize { @after_initialize_called = true }
        after_find { @after_find_called = true }

        before_create { @before_create_called = true }
        after_create { @after_create_called = true }
        before_save { @before_save_called = true }
        after_save { @after_save_called = true }
        before_update { @before_update_called = true }
        after_update { @after_update_called = true }
        before_destroy { @before_destroy_called = true }
        after_destroy { @after_destroy_called = true }
        before_validation { @before_validation_called = true }
        after_validation { @after_validation_called = true }
      end
    end

    def true_results?(node, verb)
      [node.send("before_#{verb}_called"), node.send("after_#{verb}_called")].all? { |r| r == true }
    end

    context 'unpersited objects' do
      let(:c) { Company.new }

      it 'handles after_initialize callbacks' do
        expect_any_instance_of(Company).to receive(:run_callbacks).with(:initialize)
        c
      end

      it 'handles before_save callbacks' do
        expect { c.save }.to change { true_results?(c, :save) }.from(false).to(true)
      end

      it 'handles before_validation callbacks' do
        expect { c.valid? }.to change { true_results?(c, :validation) }.from(false).to(true)
      end
    end

    context 'on persisted objects' do
      let(:c) { Company.create }

      # Because this stems from a class method, we demonstrate that it is called on objects resulting from Model.find
      it 'handles found callbacks' do
        expect(c.after_find_called).not_to eq true
        expect(Company.find(c.id).after_find_called).to eq true
      end

      it 'handles update callbacks' do
        expect { c.update(name: 'foo') }.to change { true_results?(c, :update) }
      end

      it 'handles destroy callbacks' do
        expect { c.destroy }.to change { true_results?(c, :destroy) }
      end

      include_context 'after_commit', :c, transactions_count: 0
      include_context 'after_commit', :c, transactions_count: 2
      include_context 'after_commit', :c, transactions_count: 2, fail_transaction: true
    end


    context 'that raise errors' do
      before do
        [:create, :update, :destroy].each { |m| Company.reset_callbacks(m) }
      end

      it 'rolls back node creation' do
        expect do
          expect { Company.create }.not_to raise_error
        end.to change { Company.count }

        Company.after_create { fail 'Foo error' }
        expect do
          expect { Company.create }.to raise_error RuntimeError, 'Foo error'
        end.not_to change { Company.count }
      end

      it 'rolls back node update' do
        c = Company.create(name: 'Daylight Dies')
        expect(c.name).to eq 'Daylight Dies'
        c.name = 'Katatonia'
        expect do
          expect { c.save }.not_to raise_error
        end.not_to change { c.name }.from('Katatonia')

        Company.after_update { fail 'Bar error' }

        c.name = 'October Tide'
        expect do
          expect { c.save }.to raise_error RuntimeError, 'Bar error'
          c.reload
        end.to change { c.name }.from('October Tide').to('Katatonia')
      end

      it 'rolls back node destroy' do
        c = Company.create(name: 'Foo')
        expect { expect { c.destroy }.not_to raise_error }.to change { c.persisted? }.from(true).to(false)

        Company.after_destroy { fail 'Foo error' }
        c = Company.create(name: 'Foo')

        expect { expect { c.destroy }.to raise_error(RuntimeError, 'Foo error') }.not_to change { c.persisted? }.from(true)
        expect(c).not_to be_frozen
        expect(c).not_to be_changed
      end
    end
  end

  before(:each) do
    stub_node_class('Person') do
      property :name
      property :age,          type: Integer
      property :start,        type: Time
      property :links
      property :datetime,     type: DateTime
      property :date,         type: Date
      property :time,         type: Time
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
      expect(person.neo_id).to be_nil
      person.save
      expect(person.neo_id).to be_a(Integer)
      expect(person.exist?).to be true
    end

    it 'can set properties' do
      person = Person.new(name: 'andreas', age: 21)
      expect(person[:name]).to eq('andreas')
      expect(person[:age]).to eq(21)
      person.save
      expect(person[:name]).to eq('andreas')
      expect(person[:age]).to eq(21)
    end

    it 'can create the node' do
      person = Person.create(name: 'andreas', age: 21)
      expect(person.neo_id).to be_a(Integer)
      expect(person[:name]).to eq('andreas')
      expect(person[:age]).to eq(21)
      expect(person.exist?).to be true
    end

    # Escaping strings is handled by ActiveGraph::Core but more tests never hurt.
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
      expect { Person.find_or_create_by!(name: nil) }.to raise_error ActiveGraph::Node::Persistence::RecordInvalidError
    end

    it 'can find (or initialize) by...' do
      expect(Person.find_by(name: 'Donovan', age: 30)).to be_falsey
      person = Person.find_or_initialize_by(name: 'Donovan', age: 30)
      expect(person).to be_a(ActiveGraph::Node)
      expect(person).not_to be_persisted
      expect(person.name).to eq('Donovan')
      expect(person.age).to eq(30)
    end

    it 'can (find or) initialize by...' do
      person = Person.create!(name: 'Donovan', age: 30)
      found_person = Person.find_or_initialize_by(name: 'Donovan', age: 30)
      expect(found_person).to be_a(ActiveGraph::Node)
      expect(found_person).to be_persisted
      expect(found_person).to eq(person)
    end

    describe 'create using a block' do
      let(:person) do
        Person.create do |p|
          p.name = 'Wilson'
          p.age = 50
        end
      end

      it 'persists' do
        expect(person).to be_persisted
      end

      it 'assigns property values' do
        expect(person.name).to eq 'Wilson'
        expect(person.age).to eq 50
      end

      describe 'relationships' do
        let(:person_with_rel) do
          Person.create do |p|
            p.name = 'Foo'
            p.friends << other_person
          end
        end
        let(:other_person) { Person.create(name: 'Bar') }

        before do
          Person.has_many(:out, :friends, model_class: 'Person', type: 'FRIENDS_WITH')
          person_with_rel.reload
        end

        it 'are persisted' do
          expect(person_with_rel.friends.first).to eq other_person
        end
      end
    end
    # This also works for create! and find_by_or_create/find_by_or_create!
    it 'can increment an attribute' do
      person = Person.create(name: 'andreas', age: 21)
      expect { person.increment(:age) }.to change { person.age }.from(21).to(22)
    end

    it 'can increment an attribute and save' do
      person = Person.create(name: 'andreas', age: 21)
      expect { person.increment!(:age) }.to change { person.age }.from(21).to(22)
      expect(person).not_to be_changed
    end

    it 'can increment an attribute (concurrently)' do
      person = Person.create(name: 'andreas', age: 21)
      same_person = Person.last
      person.concurrent_increment!(:age)
      expect(person.age).to eq(22)
      expect(person.age_was).to eq(22)
      same_person.concurrent_increment!(:age)
      expect(person.reload.age).to eq(23)
      expect(same_person.age).to eq(23)
    end

    it 'can be deleted' do
      person = Person.create(name: 'andreas', age: 21)
      person.destroy
      expect(person.persisted?).to be false
    end

    it 'can be loaded by id' do
      person1 = Person.create(name: 'andreas', age: 21)
      person2 = Person.find(person1.id)
      expect(person2.id).to eq(person1.id)
      expect(person2.neo_id).to eq(person1.neo_id)
    end

    it 'does not persist updated properties until they are saved' do
      person = Person.create(name: 'andreas', age: 21)
      person[:age] = 22

      expect(Person.find(person.id).age).to eq(21)
    end

    it 'should not clear out existing properties when property is set and saved' do
      person = Person.create(name: 'andreas', age: 21)
      person.age = 22
      person.save

      person2 = neo4j_query('MATCH (p:Person) WHERE ID(p) = $neo_id RETURN p',
                            {neo_id: person.neo_id},
                            wrap: false).first[:p]
      expect(person2.properties).to match hash_including age: 22, name: 'andreas'
    end

    it 'they can be all found' do
      person1 = Person.create(name: 'person1', age: 21)
      person2 = Person.create(name: 'person2', age: 21)
      expect(Person.all).to include(person1, person2)
    end

    it 'they can be queries' do
      Person.create(name: 'person3', age: 21)
      person2 = Person.create(name: 'person4', age: 21)
      expect(Person.where(name: 'person4').to_a.map(&:neo_id)).to eq([person2.neo_id])
    end

    it 'saves all declared properties' do
      expect do
        Person.create(name: 'person123', age: 123, unknown: 'yes')
      end.to raise_error(ActiveGraph::Shared::Property::UndefinedPropertyError)
    end

    it 'does not have the weird bug described in issue #761' do
      stub_node_class('Community') do
        property :name
      end

      stub_node_class('School') do
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

      context Time do
        it 'converts to Time' do
          person = Person.create('time(1i)' => '1', 'time(2i)' => '1', 'time(3i)' => '1', 'time(4i)' => '9', 'time(5i)' => '12', 'time(6i)' => '42', 'time(7s)' => '+00:00')
          expect(person.time).to be_a(Time)
          expect(person.time.utc.hour).to eq 9
          expect(person.time.utc.min).to eq 12
          expect(person.time.utc.sec).to eq 42
        end
      end

      it 'raises an error when it receives values it cannot process' do
        expect do
          Person.create('foo(1i)' => '2014', 'foo(2i)' => '2014')
        end.to raise_error(ActiveGraph::Shared::Property::MultiparameterAssignmentError)
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
      query = new_query.match(p: :Person)
                       .where(p: {neo_id: person.neo_id})
                       .return('p.datetime AS datetime')
      ActiveGraph::Base.query(query).first[:datetime]
    end

    it 'saves as date/time string by default' do
      expect(datetime_db_value).to eq(1_420_146_245)
    end
  end

  describe 'cache_key' do
    describe 'unpersisted object' do
      it 'should respond with plural_model/new' do
        model = IceLolly.new
        expect(model.cache_key).to eq "#{model.class.model_name.cache_key}/new"
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
          stub_node_class('NoStamp') do
            property :name
          end
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
      stub_node_class('Cat') do
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
              expect { Cat.as(:c).all(:another_variable).named_jim.pluck(:c) }
                .to raise_error Neo4j::Driver::Exceptions::ClientException, /Variable `c` not defined/
              expect(Cat.as(:c).all(:another_variable).named_jim.pluck(:another_variable)).to eq [jim]
            end
          end
        end
      end
    end
  end

  describe 'ActiveGraph::Paginated.create_from' do
    before do
      Person.delete_all
      i = 1.upto(16).to_a
      i.each { |count| Person.create(name: "Billy-#{i}", age: count) }
    end

    let(:t) { Person.where }
    let(:p) { ActiveGraph::Paginated.create_from(t, 2, 5) }

    it 'returns a ActiveGraph::Paginated' do
      expect(p).to be_a(ActiveGraph::Paginated)
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
        person = ActiveGraph::Paginated.create_from(Person.all, 1, 2, :name)
        expect(person.count).to eq 2
        expect(person.first.name).to eq 'Alice'
      end

      it 'allows ordering with a hash' do
        person = ActiveGraph::Paginated.create_from(Person.all, 1, 2, name: :desc)
        expect(person.count).to eq 2
        expect(person.first.name).to eq 'David'
      end
    end
  end

  describe 'finding by id_property' do
    let(:activenode_class) { node_class('TestClass') }
    let(:object) { activenode_class.create }

    describe 'where' do
      it 'should use uuid' do
        expect(activenode_class.where(id: object).first).to eq(object)
        expect(activenode_class.where(id: object.id).first).to eq(object)
        expect(activenode_class.where(id: id_property_value(object)).first).to eq(object)
      end

      context 'different id_property is specified' do
        let(:activenode_class) do
          node_class('TestClass') do
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
        expect(activenode_class.find_by(id: id_property_value(object))).to eq(object)
      end

      context 'different id_property is specified' do
        let(:activenode_class) do
          node_class('TestClass') do
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

  context 'with `ActionController::Parameters`' do
    let(:params) { action_controller_params('prop_with_default' => 'something else') }
    let(:create_params) { params }
    let(:klass) { IceLolly }
    let(:subject) { klass.new }

    it_should_behave_like 'handles permitted parameters'
  end
end
