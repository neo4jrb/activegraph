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

  describe 'basic persistance' do

    Person = UniqueClass.create do
      include Neo4j::ActiveNode
      property :name
      property :age,   type: Integer
      property :start,  type: Time
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
      end.to raise_error(Neo4j::ActiveNode::Property::UndefinedPropertyError)
    end
  end

end
