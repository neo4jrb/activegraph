require 'spec_helper'
require "shared_examples/new_model"
require "shared_examples/loadable_model"
require "shared_examples/saveable_model"

describe Neo4j::ActiveNode do
  class SimpleClass
    include Neo4j::ActiveNode
    property :name
  end

  describe SimpleClass do
    context 'when instantiated with new()' do
      subject do
        SimpleClass.new
      end

      include_examples "new model"
      include_examples "loadable model"
      include_examples "saveable model"

      it 'does not have any attributes' do
        subject.attributes.should == {"name" => nil}
      end

      it 'returns nil when asking for a attribute' do
        subject['name'].should be_nil
      end

      it 'can set attributes' do
        subject['name'] = 'foo'
        subject['name'].should == 'foo'
      end

      it 'allows symbols instead of strings in [] and []= operator' do
        subject[:name] = 'foo'
        subject['name'].should == 'foo'
        subject[:name].should == 'foo'
      end

      it 'allows setting attributes to nil' do
        subject['name'] = nil
        subject['name'].should be_nil
        subject['name'] = 'foo'
        subject['name'] = nil
        subject['name'].should be_nil
      end

    end

    context 'when instantiated with new(name: "foo")' do
      subject() { SimpleClass.new(unknown: 'foo')}

      it 'does not allow setting undeclared properties' do
        # TODO do we really want this behaviour ???
        subject.props.should == {}
      end
    end
  end

end

class IceLolly
  include Neo4j::ActiveNode
  property :flavour
  property :required_on_create
  property :required_on_update
  property :created

  attr_reader :saved

  index :flavour

  validates :flavour, :presence => true
  validates :required_on_create, :presence => true, :on => :create
  validates :required_on_update, :presence => true, :on => :update

  # TODO support for create callbacks
  #before_create :timestamp
  #after_create :mark_saved

  protected
  def timestamp
    self.created = "yep"
  end

  def mark_saved
    @saved = true
  end
end


class IceCream
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
      attr_accessor :update_called, :save_called, :destroy_called
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
    end

    it 'handles before_save callbacks' do
      c = Company.new
      c.save_called.should be_nil
      c.save
      c.save_called.should be_true
    end

    it 'handles before_update callbacks' do
      c = Company.create
      c.update(:name => 'foo')
      expect(c.update_called).to be_true
    end

    it 'handles before_destroy callbacks' do
      c = Company.create
      c.destroy
      expect(c.destroy_called).to be_true
    end

  end

  describe 'inheritance' do
    class BasePerson
      include Neo4j::ActiveNode
    end

    class SubPerson < BasePerson

    end

    it 'finds it using both sub and base class' do
      #pending "it does not wrap with the subclass"
      s = SubPerson.create
      res = BasePerson.all
      res.to_a.should include(s)

      # sub class
      res = SubPerson.all
      res.to_a.should include(s)
    end
  end

  describe 'basic persistance' do

    class Person
      include Neo4j::ActiveNode
      attribute :name
      attribute :age, type: Integer
    end

    it 'generate accessors for declared attribute' do
      person = Person.new(:name => "hej")
      expect(person.name).to eq("hej")
      person.name = 'new name'
      expect(person.name).to eq("new name")
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
      person.exist?.should be_true
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
      person.exist?.should be_true
    end

    it 'can be deleted' do
      person = Person.create(name: 'andreas', age: 21)
      person.destroy
      person.exist?.should be_false
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


    it "they can be all found" do
      person1 = Person.create(name: 'person1', age: 21)
      person2 = Person.create(name: 'person2', age: 21)
      Person.all.should include(person1, person2)
    end

    it 'saves all declared properties' do
      person1 = Person.create(name: 'person123', age: 123, unknown: "yes")
      id = person1.id
      person = Neo4j::Node.load(id)
      person.name.should == 'person123'
      person.age.should == 123
      expect{person[:unknown]}.to raise_error(ActiveAttr::UnknownAttributeError)
    end
  end

end