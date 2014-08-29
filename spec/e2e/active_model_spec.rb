require 'spec_helper'

IceLolly = UniqueClass.create do
  include Neo4j::ActiveNode
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

  validates :flavour, :presence => true
  validates :required_on_create, :presence => true, :on => :create
  validates :required_on_update, :presence => true, :on => :update

  before_create :timestamp
  after_create :mark_saved

  protected
  def timestamp
    self.created = "yep"
  end

  def mark_saved
    @saved = true
  end
end

#class ExtendedIceLolly < IceLolly
#  property :extended_property
#end

describe IceLolly, :type => :integration do
  context "when valid" do
    before :each do
      subject.flavour = "vanilla"
      subject.required_on_create = "true"
      subject.required_on_update = "true"
    end

    it_should_behave_like "new model"
    it_should_behave_like "loadable model"
    it_should_behave_like "saveable model"
    it_should_behave_like "creatable model"
    it_should_behave_like "destroyable model"
    it_should_behave_like "updatable model"
    it_should_behave_like "timestamped model"

    context "after being saved" do
      before do
        subject.class.destroy_all
        subject.save
      end

      #it { subject.id.should == subject.class.find(flavour: 'vanilla').id}

      it { should == subject.class.where(flavour: 'vanilla').first }

      it "should be able to modify one of its named attributes" do
        lambda{ subject.update_attributes!(:flavour => 'horse') }.should_not raise_error
        subject.flavour.should == 'horse'
      end

      it "should not have the extended property" do
        subject.attributes.should_not include("extended_property")
      end

      it "should respond to class.all" do
        subject.class.respond_to?(:all)
      end

      it "should respond to class#all(:flavour => 'vanilla')" do
        subject.class.where(flavour: 'vanilla').should include(subject)
      end

      context "and then made invalid" do
        before { subject.required_on_update = nil }

        it "shouldn't be updatable" do
          subject.update_attributes(:flavour => "fish").should_not be true
        end

        it "should have the same attribute values after an unsuccessful update and reload" do
          subject.update_attributes(:flavour => "fish")
          subject.reload.flavour.should == "vanilla"
          subject.required_on_update.should_not be_nil
        end

      end
    end

    context "after create" do
      before :each do
        @obj = subject.class.create!(subject.attributes)
      end

      it "should have run the #timestamp callback" do
        @obj.created.should_not be_nil
      end

      it "should have run the #mark_saved callback" do
        @obj.saved.should_not be_nil
      end
    end
  end

  context "when invalid" do
    it_should_behave_like "new model"
    it_should_behave_like "unsaveable model"
    it_should_behave_like "uncreatable model"
    it_should_behave_like "non-updatable model"
  end
end


#describe ExtendedIceLolly, :type => :integration do
#
#  it "should have inherited all the properties" do
#    subject.attribute_names.should include("flavour")
#  end
#
#  it { should respond_to(:flavour) }
#
#  context "when valid" do
#    subject { ExtendedIceLolly.new(:flavour => "vanilla", :required_on_create => "true", :required_on_update => "true") }
#
#    it_should_behave_like "new model"
#    it_should_behave_like "loadable model"
#    it_should_behave_like "saveable model"
#    it_should_behave_like "creatable model"
#    it_should_behave_like "destroyable model"
#    it_should_behave_like "updatable model"
#
#    context "after being saved" do
#      before { subject.save }
#
#      it { should == subject.class.find(flavour: 'vanilla') }
#    end
#  end
#end
#

IceCream = UniqueClass.create do
  include Neo4j::ActiveNode
  property :flavour, :index => :exact
  #has_n(:ingredients).to(Ingredient)
  validates_presence_of :flavour
end

describe Neo4j::ActiveNode do


  describe 'validations' do

    it 'does not have any errors if its valid' do
      ice_cream = IceCream.new(flavour: 'strawberry')
      ice_cream.should be_valid
      ice_cream.errors.should be_empty
    end

    it 'does have errors if its not valid' do
      ice_cream = IceCream.new()
      ice_cream.should_not be_valid
      ice_cream.errors.should_not be_empty
    end
  end


  describe 'callbacks' do
    class Company
      attr_accessor :update_called, :save_called, :destroy_called, :validation_called
      include Neo4j::ActiveNode

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

    it 'handles before_save callbacks' do
      c = Company.new
      c.save_called.should be_nil
      c.save
      c.save_called.should be true
    end

    it 'handles before_update callbacks' do
      c = Company.create
      c.update(:name => 'foo')
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

  end

  describe 'cached classnames' do
    CacheTest = UniqueClass.create do
      include Neo4j::ActiveNode
    end

    context 'with cache_class set in config' do
      before do
        Neo4j::Config[:cache_class_names] = true
        @cached = CacheTest.create
        @unwrapped = Neo4j::Node._load(@cached.id)
      end

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

    context 'without cache_class set in model' do
      before do
        Neo4j::Config[:cache_class_names] = false
        @uncached = CacheTest.create
        @unwrapped = Neo4j::Node._load(@uncached.id)
      end

      before { Neo4j::Config[:cache_class_names] = false }

      it 'response false to :cached_class?' do
        expect(CacheTest.cached_class?).to be_falsey
      end

      it "does not set _classname on the node" do
        expect(@unwrapped.props).to_not have_key(:_classname)
      end
    end
  end

  describe 'basic persistance' do

    Person = UniqueClass.create do
      include Neo4j::ActiveNode
      property :name
      property :age,          type: Integer
      property :start,        type: Time
      property :links
      property :datetime,     type: DateTime
      property :date,         type: Date
      property :numbers

      serialize :links
    end

    it 'generate accessors for declared attribute' do
      person = Person.new(:name => "hej")
      expect(person.name).to eq("hej")
      person.name = 'new name'
      expect(person.name).to eq("new name")
    end

    it 'accepts Time type, converts to DateTime' do
      person = Person.create(start: Time.now)
      person.start.class.should eq(DateTime)
    end

    it 'declared attribute can have type conversion' do
      person = Person.create(age: "40")
      expect(person.age).to eq(40)
      person.age = '42'
      person.save()
      expect(person.age).to eq(42)
    end

    it 'attributes and [] accessors can be combined' do
      person = Person.create(age: "40")
      expect(person.age).to eq(40)
      expect(person[:age]).to eq(40)
      expect(person['age']).to eq(40)
      person[:age] = "41"
      expect(person.age).to eq(41)

      expect(person['age']).to eq(41)
      expect(person[:age]).to eq(41)

    end

    it 'can persist a new object' do
      person = Person.new
      person.neo_id.should be_nil
      person.save
      person.neo_id.should be_a(Fixnum)
      person.exist?.should be true
    end

    it 'can set properties' do
      person = Person.new(name: 'andreas', age: 21)
      person[:name].should == 'andreas'
      person[:age].should == 21
      person.save
      person[:name].should == 'andreas'
      person[:age].should == 21
    end

    it 'can create the node' do
      person = Person.create(name: 'andreas', age: 21)
      person.neo_id.should be_a(Fixnum)
      person[:name].should == 'andreas'
      person[:age].should == 21
      person.exist?.should be true
    end

    it 'can be deleted' do
      person = Person.create(name: 'andreas', age: 21)
      person.destroy
      person.exist?.should be false
    end

    it 'can be loaded by id' do
      person1 = Person.create(name: 'andreas', age: 21)
      person2 = Neo4j::Node.load(person1.neo_id)
      person2.neo_id.should == person1.neo_id
      person2.should == person1
    end

    it 'does not persist updated properties until they are saved' do
      person = Person.create(name: 'andreas', age: 21)
      person[:age] = 22

      person2 = Neo4j::Node.load(person.neo_id)
      person2[:age].should == 21
    end
    
    it 'should not clear out existing properties when property is set and saved' do
      person = Person.create(name: 'andreas', age: 21)
      person.age = 22
      person.save
      person2 = Neo4j::Node.load(person.neo_id)
      person2.age.should == 22
      person2.name.should == "andreas"
    end

    it "they can be all found" do
      person1 = Person.create(name: 'person1', age: 21)
      person2 = Person.create(name: 'person2', age: 21)
      Person.all.should include(person1, person2)
    end

    it "they can be queries" do
      Person.create(name: 'person3', age: 21)
      person2 = Person.create(name: 'person4', age: 21)

      Person.where(name: 'person4').to_a.should == [person2]
    end

    it 'saves all declared properties' do
      expect do
        Person.create(name: 'person123', age: 123, unknown: "yes")
      end.to raise_error(Neo4j::Shared::Property::UndefinedPropertyError)
    end

    describe 'multiparameter attributes' do
      it 'converts to Date' do
        person = Person.create("date(1i)"=>"2014", "date(2i)"=>"7", "date(3i)"=>"13")
        expect(person.date).to be_a(Date)
        expect(person.date.to_s).to eq("2014-07-13")
      end

      it 'converts to DateTime' do
        person = Person.create("datetime(1i)"=>"2014", "datetime(2i)"=>"7", "datetime(3i)"=>"13", "datetime(4i)"=>"17", "datetime(5i)"=>"45")
        expect(person.datetime).to be_a(DateTime)
        expect(person.datetime).to eq 'Sun, 13 Jul 2014 17:45:00 +0000'
      end

      it 'raises an error when it receives values it cannot process' do
        expect do
          Person.create("foo(1i)"=>"2014", "foo(2i)"=>"2014")
        end.to raise_error(Neo4j::Shared::Property::MultiparameterAssignmentError)
      end

      it 'sends values straight through when no type is specified' do
        person = Person.create("numbers(1i)" => "5", "numbers(2i)" => "23")
        expect(person.numbers).to be_a(Array)
        expect(person.numbers).to eq [5, 23]
      end

      it "leaves standard attributes alone" do
        person = Person.create("date(1i)"=>"2014", "date(2i)"=>"7", "date(3i)"=>"13", name: 'chris')
        expect(person.name).to eq 'chris'
        expect(person.date).to be_a(Date)
      end
    end
  end

  describe 'serialization' do
    let!(:chris) { Person.create(name: 'chris') }
    
    it 'correctly identifies properties for serialization' do
      expect(Person.serialized_properties).to include(:links)
      expect(chris.serialized_properties).to include(:links)
    end

    it 'successfully saves and returns hashes' do
      links = {neo4j: 'http://www.neo4j.org', neotech: 'http://www.neotechnology.com/' }
      chris.links = links
      chris.save
      expect(chris.links).to eq links
      expect(chris.links.class).to eq Hash
    end
  end

  describe "cache_key" do
    describe "unpersisted object" do
      it "should respond with plural_model/new" do
        model = IceLolly.new
        model.cache_key.should eq "#{model.class.model_name.cache_key}/new"
      end
    end

    describe "persisted object" do
      let(:model) { IceLolly.create(flavour: "vanilla", required_on_create: true, required_on_update: true) }

      it "should respond with a valid cache key" do
        expect(model.cache_key).to eq "#{model.class.model_name.cache_key}/#{model.neo_id}-#{model.updated_at.utc.to_s(:number)}"
      end

      context "when changed" do
        it "should change cache_key value" do
          start = model.cache_key and sleep 1
          model.flavour = "chocolate" and model.save
          expect(model.cache_key).to_not eq start
        end
      end

      describe 'without updated_at property' do
        NoStamp = UniqueClass.create do
          include Neo4j::ActiveNode
          property :name

        end
        let (:nostamp) { NoStamp.create }
        it 'returns cache key without timestamp' do
          expect(nostamp.cache_key).to eq "#{nostamp.class.model_name.cache_key}/#{nostamp.neo_id}"
        end
      end
    end
  end

  describe 'node with rel_class set' do
    class ToClass; end
    class MyRelClass; end

    class FromClass
      include Neo4j::ActiveNode
      has_many :out, :others, model_class: ToClass, rel_class: MyRelClass
    end

    class ToClass
      include Neo4j::ActiveNode
      has_many :in, :others, model_class: FromClass, rel_class: MyRelClass
    end

    class MyRelClass
      include Neo4j::ActiveRel
      from_class FromClass
      to_class ToClass
      type 'rel_class_type'
    end

    context 'with rel created from node' do
      it 'returns the activerel class' do
        f1 = FromClass.create
        t1 = ToClass.create
        f1.others << t1
        expect(f1.rels.first).to be_a(MyRelClass)
      end
    end

    context 'with rel created from activerel' do
      let(:from_node) { FromClass.create }
      let(:to_node) { ToClass.create }

      it 'creates the rel' do
        rel = MyRelClass.create(from_node: from_node, to_node: to_node)
        expect(rel.from_node).to eq from_node
        expect(rel.to_node).to eq to_node
        expect(rel.persisted?).to be_truthy
      end
    end
  end

  describe 'include?, exists?, count' do
    #goofy names to differentiate from same classes used elsewhere
    before(:all) do
      class IncludeLesson; end
      class IncludeTeacher; end
      class IncludeEmptyClass; end
      class IncludeStudent
        include Neo4j::ActiveNode
        property :name
        has_many :out, :lessons, model_class: IncludeLesson, type: 'lessons'
      end

      class IncludeLesson
        include Neo4j::ActiveNode
        property :name
        has_many :in, :students, model_class: IncludeStudent, origin: :lessons
        has_many :in, :teachers, model_class: IncludeTeacher, origin: :lessons
      end

      class IncludeTeacher
        include Neo4j::ActiveNode
        has_many :out, :lessons, model_class: IncludeLesson, type: 'teaching_lesson'
      end

      class IncludeEmptyClass
        include Neo4j::ActiveNode
        has_many :out, :lessons, model_class: IncludeLesson
      end
    end
    let!(:jimmy)    { IncludeStudent.create(name: 'Jimmy') }
    let!(:math)     { IncludeLesson.create(name: 'math') }
    let!(:science)  { IncludeLesson.create(name: 'science') }
    let!(:mr_jones) { IncludeTeacher.create }
    let!(:mr_adams) { IncludeTeacher.create }

    describe 'first and last' do
      it 'returns objects across multiple associations' do
        jimmy.lessons << science
        science.teachers << mr_adams
        expect(jimmy.lessons.teachers.first).to eq mr_adams
        expect(mr_adams.lessons.students.last).to eq jimmy
      end
    end

    describe 'include?' do
      it 'correctly reports when a node is included in a query result' do
        jimmy.lessons << science
        science.teachers << mr_adams
        expect(jimmy.lessons.include?(science)).to be_truthy
        expect(jimmy.lessons.include?(math)).to be_falsey
        expect(jimmy.lessons.teachers.include?(mr_jones)).to be_falsey
        expect(jimmy.lessons.where(name: 'science').teachers.include?(mr_jones)).to be_falsey
        expect(jimmy.lessons.where(name: 'science').teachers.include?(mr_adams)).to be_truthy
        expect(IncludeTeacher.include?(mr_jones)).to be_truthy
        expect(IncludeTeacher.include?(math)).to be_falsey
      end

      it 'works with multiple relationships to the same object' do
        jimmy.lessons << science
        jimmy.lessons << science
        expect(jimmy.lessons.include?(science)).to be_truthy
      end

      it 'allows you to check for an identifier in the middle of a chain' do
        jimmy.lessons << science
        science.teachers << mr_adams
        expect(IncludeLesson.as(:l).students.where(name: 'Jimmy').include?(science, :l)).to be_truthy
      end

      it 'raises an error if something other than a node is given' do
        expect{IncludeStudent.lessons.include?(:foo)}.to raise_error(Neo4j::ActiveNode::Query::InvalidParameterError)
      end
    end

    describe 'exists?' do
      it 'can run on a class' do
        expect(IncludeEmptyClass.empty?).to be_truthy
        expect(IncludeLesson.empty?).to be_falsey
      end
      
      it 'can be run on a query' do
        expect(IncludeLesson.where(name: 'history').exists?).to be_falsey
        expect(IncludeLesson.where(name: 'math').exists?).to be_truthy
      end

      it 'can be run with a neo_id' do
        expect(IncludeLesson.where(name: 'math').exists?(math.neo_id)).to be_truthy
        expect(IncludeLesson.where(name: 'math').exists?(science.neo_id)).to be_falsey
      end

      it 'can be called by the class with a neo_id' do
        expect(IncludeLesson.exists?(math.neo_id)).to be_truthy
        expect(IncludeLesson.exists?(8675309)).to be_falsey
      end

      it 'raises an error if something other than a neo id is given' do
        expect{IncludeLesson.exists?(:fooooo)}.to raise_error(Neo4j::ActiveNode::Labels::InvalidParameterError)
      end

      it 'is called by :blank? and :empty?' do
        expect(jimmy.lessons.blank?).to be_truthy
        expect(jimmy.lessons.empty?).to be_truthy
        jimmy.lessons << science
        expect(jimmy.lessons.blank?).to be_falsey
        expect(jimmy.lessons.empty?).to be_falsey
      end
    end

    describe 'count' do
      before(:all) do
        @john = IncludeStudent.create(name: 'Paul')
        @history = IncludeLesson.create(name: 'history')
        3.times { @john.lessons << @history }
      end

      it 'tells you the number of matching objects' do
        expect(@john.lessons.count).to eq(3)
      end

      it 'can tell you the number of distinct matching objects' do
        expect(@john.lessons.count(:distinct)).to eq 1
      end

      it 'raises an exception if a bad parameter is passed' do
        expect{@john.lessons.count(:foo)}.to raise_error(Neo4j::ActiveNode::Query::InvalidParameterError)
      end

      it 'works on an object earlier in the chain' do
        expect(IncludeStudent.as(:s).lessons.where(name: 'history').count(:distinct, :s)).to eq 1
      end

      it 'is aliased by length and size' do
        expect(@john.lessons.size).to eq(3)
        expect(@john.lessons.length).to eq(3)
      end
    end
  end

  describe "Neo4j::Paginated.create_from" do
    before {
      Person.destroy_all
      i = 1.upto(16).to_a
      i.each{|i| Person.create(age: i) }
    }
    after(:all) { Person.destroy_all }
    let(:t) { Person.where }
    let(:p) { Neo4j::Paginated.create_from(t, 2, 5) }

    it "returns a Neo4j::Paginated" do
      expect(p).to be_a(Neo4j::Paginated)
    end

    it 'returns the expected number of objects' do
      expect(p.count).to eq 5
    end
  end
end
