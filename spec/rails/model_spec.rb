require File.join(File.dirname(__FILE__), '..', 'spec_helper')

# Specs written by Nick Sieger and modified by Andreas Ronge

class Ingredience < Neo4j::Model
  property :name
end

class IceCream < Neo4j::Model
  property :flavour
  index :flavour
  rule(:all)
  has_n :ingrediences

  validates_presence_of :flavour
end

describe Neo4j::Model do

  before(:all) do
    rm_db_storage
  end

  after(:all) do
    Neo4j.shutdown
    rm_db_storage
  end

  describe "new" do
    before :each do
      @model = Neo4j::Model.new
    end
    subject { @model }

    it { should_not be_persisted }

    it "should allow access to properties before it is saved" do
      @model["fur"] = "none"
      @model["fur"].should == "none"
    end

    it "validation is performed when properties are changed" do
      v = IceCream.new
      v.should_not be_valid
      v.flavour = 'vanilla'
      v.should be_valid
    end

    it "validation is performed after save" do
      v = IceCream.new(:flavour => 'vanilla')
      v.save
      v.should be_valid
    end


    it "accepts a hash of properties which will be validated" do
      v = IceCream.new(:flavour => 'vanilla')
      v.should be_valid
    end


    it "save should create a new node" do
      v = IceCream.new(:flavour => 'q')
      v.save
      Neo4j::Node.should exist(v)
    end

    it "has nil as id befored saved" do
      v = IceCream.new(:flavour => 'andreas')
      v.id.should == nil
    end

  end

  describe "load" do
    it "should load a previously stored node" do
      model = Neo4j::Model.create
      result = Neo4j::Model.load(model.id)
      result.should == model
      result.should be_persisted
    end
  end


  describe "save" do
    it "stores a new model in the database" do
      model = IceCream.new
      model.flavour = "vanilla"
      model.save
      model.should be_persisted
      IceCream.load(model.id).should == model
    end

    it "stores a created and modified model in the database" do
      model = nil
      IceCream.transaction do
        model = IceCream.new
        model.flavour = "vanilla"
        model.save
      end
      model.should be_persisted
      IceCream.load(model.id).should == model
    end

    it "does not save the model if it is invalid" do
      model = IceCream.new
      model.save.should_not be_true
      model.should_not be_valid

      model.should_not be_persisted
      model.id.should be_nil
    end

    it "new_record? is false before saved and true after saved (if saved was successful)" do
      model = IceCream.new(:flavour => 'vanilla')
      model.should be_new_record
      model.save.should be_true
      model.should_not be_new_record
    end

    it "does not modify the attributes if validation fails when run in a transaction" do
      model = IceCream.create(:flavour => 'vanilla')

      IceCream.transaction do
        model.flavour = nil
        model.flavour.should be_nil
        model.should_not be_valid
        model.save
      end

      model.flavour.should == 'vanilla'
    end
  end


  describe "error" do
    it "the validation method 'errors' returns the validation errors" do
      p = IceCream.new
      p.should_not be_valid
      p.errors.keys[0].should == :flavour
      p.flavour = 'vanilla'
      p.should be_valid
      p.errors.size.should == 0
    end
  end

  describe "ActiveModel::Dirty" do

    it "implements attribute_changed?, _change, _changed, _was, _changed? methods" do
      p = IceCream.new
      p.should_not be_changed
      p.flavour = 'kalle'
      p.should be_changed
      p.attribute_changed?('flavour').should == true
      p.flavour_change.should == [nil, 'kalle']
      p.flavour_was.should == nil
      p.flavour_changed?.should be_true
      p.flavour_was.should == nil

      p.flavour = 'andreas'
      p.flavour_change.should == ['kalle', 'andreas']
      p.save
      p.should_not be_changed
    end
  end

  describe "find" do
    it "should load all nodes of that type from the database" do
      model = IceCream.create :flavour => 'vanilla'
      IceCream.all.should include(model)
    end

    it "should find the node given it's id" do
      model = IceCream.create(:flavour => 'thing')
      IceCream.find(model.neo_id.to_s).should == model
    end


    it "should find a model by one of its attributes" do
      model = IceCream.create(:flavour => 'vanilla')
      IceCream.find("flavour: vanilla").to_a.should include(model)
    end
  end

  describe "destroy" do
    before :each do
      @model = Neo4j::Model.create
    end

    it "should remove the model from the database" do
      id = @model.neo_id
      @model.destroy
      Neo4j::Node.load(id).should be_nil
    end
  end

  describe "create" do

    it "if failed since saved returned false it should fail the whole transaction it is part of" do
      illegal_icecream = valid_icecream = nil
      IceCream.transaction do
        valid_icecream   = IceCream.create(:flavour => 'vanilla')
        illegal_icecream = IceCream.create(:flavour => nil)
      end

      # then
      Neo4j::Node.load(illegal_icecream.neo_id).should be_nil
      valid_icecream.should_not exist
      illegal_icecream.should_not exist
    end

    it "should save the model and return it" do
      model = Neo4j::Model.create
      model.should be_persisted
    end

    it "should accept attributes to be set" do
      model = Neo4j::Model.create :name => "Nick"
      model[:name].should == "Nick"
    end

    it "bang version should raise an exception if save returns false" do
      expect { IceCream.create! }.to raise_error(Neo4j::Model::RecordInvalidError)
    end

    it "bang version should NOT raise an exception" do
      icecream = IceCream.create! :flavour => 'vanilla'
      icecream.flavour.should == 'vanilla'
    end

    it "should run before and after create callbacks" do
      klass = model_subclass do
        property :created
        before_create :timestamp

        def timestamp
          self.created = "yes"
          fail "Expected new record" unless new_record?
        end

        after_create :mark_saved
        attr_reader :saved

        def mark_saved
          @saved = true
          fail "Expected new record" unless new_record?
        end
      end
      model = klass.create!
      model.created.should_not be_nil
      model.saved.should_not be_nil
    end

    it "should run before and after save callbacks" do
      klass = model_subclass do
        property :created
        before_save :timestamp

        def timestamp
          self.created = "yes"
          fail "Expected new record" unless new_record?
        end

        after_save :mark_saved
        attr_reader :saved

        def mark_saved
          fail "Expected new record" unless new_record?
          @saved = true
        end
      end
      model = klass.create!
      model.created.should_not be_nil
      model.saved.should_not be_nil
    end

    it "should run before and after new & save callbacks" do
      klass = model_subclass do
        property :created
        before_save :timestamp

        def timestamp
          self.created = "yes"
          fail "Expected new record" unless new_record?
        end

        after_save :mark_saved
        attr_reader :saved

        def mark_saved
          fail "Expected new record" unless new_record?
          @saved = true
        end
      end
      model = klass.new
      model.save
      model.created.should_not be_nil
      model.saved.should_not be_nil
    end

  end

  describe "update_attributes" do
    it "should save the attributes" do
      model = Neo4j::Model.new
      model.update_attributes(:a => 1, :b => 2).should be_true
      model[:a].should == 1
      model[:b].should == 2
    end

    it "should not update the model if it is invalid" do
      klass = model_subclass do
        property :name
        validates_presence_of :name
      end
      model = klass.create!(:name => "vanilla")
      model.update_attributes(:name => nil).should be_false
      model.name.should == "vanilla"
    end
  end

  describe "properties" do
    it "not required to run in a transaction (will create one)" do
      cream = IceCream.create :flavour => 'x'
      cream.flavour = 'vanilla'

      cream.flavour.should == 'vanilla'
      cream.should exist
    end

    it "should reuse the same transaction - not create a new one if one is already available" do
      cream = nil
      IceCream.transaction do
        cream = IceCream.create :flavour => 'x'
        cream.flavour = 'vanilla'
        cream.should exist

        # create an icecream that will rollback the transaction
        IceCream.create
      end

      cream.should_not exist
    end
  end

  describe "Neo4j::UniquenessValidator" do
    before(:all) do
      class ValidThing < Neo4j::Model
        index :email
        validates :email, :uniqueness => true
      end
      @klass = ValidThing
    end

    it "have correct kind" do
      Neo4j::Validations::UniquenessValidator.kind.should == :uniqueness
    end
    it "should not allow to create two nodes with unique fields" do
      a = @klass.create(:email => 'abc@se.com')
      b = @klass.new(:email => 'abc@se.com')

      b.save.should be_false
      b.errors.size.should == 1
    end

    it "should not allow to create two nodes with not unique fields" do
      @klass.create(:email => 'abc@gmail.copm')
      b = @klass.new(:email => 'ab@gmail.com')

      b.save.should be_true
      b.errors.size.should == 0
    end

  end


  describe "attr_accessible" do
    before(:all) do
      @klass = model_subclass do
        attr_accessor :name, :credit_rating
        attr_protected :credit_rating
      end
    end
    it "given attributes are sanitized before assignment in method: attributes" do
      customer = @klass.new
      customer.attributes = {"name" => "David", "credit_rating" => "Excellent"}
      customer.name.should == 'David'
      customer.credit_rating.should be_nil

      customer.credit_rating= "Average"
      customer.credit_rating.should == 'Average'
    end

    it "given attributes are sanitized before assignment in method: new" do
      customer = @klass.new("name" => "David", "credit_rating" => "Excellent")
      customer.name.should == 'David'
      customer.credit_rating.should be_nil

      customer.credit_rating= "Average"
      customer.credit_rating.should == 'Average'
    end

    it "given attributes are sanitized before assignment in method: create" do
      customer = @klass.create("name" => "David", "credit_rating" => "Excellent")
      customer.name.should == 'David'
      customer.credit_rating.should be_nil

      customer.credit_rating= "Average"
      customer.credit_rating.should == 'Average'
    end

    it "given attributes are sanitized before assignment in method: update_attributes" do
      customer = @klass.new
      customer.update_attributes("name" => "David", "credit_rating" => "Excellent")
      customer.name.should == 'David'
      customer.credit_rating.should be_nil

      customer.credit_rating= "Average"
      customer.credit_rating.should == 'Average'
    end
  end

  describe "nested attributes" do
    it "adding nodes to a has_n method created with the #new method" do
      icecream = IceCream.new
      suger = Ingredience.new :name => 'suger'
      icecream.ingrediences << suger
      icecream.ingrediences.should include(suger)
      icecream.outgoing(:ingrediences).should include(suger)
    end

    it "adding nodes using outgoing should work for models created with the #new method" do
      icecream = IceCream.new
      suger = Ingredience.new :name => 'suger'
      icecream.outgoing(:ingrediences) << suger
      icecream.outgoing(:ingrediences).should include(suger)
      icecream.ingrediences.should include(suger)
    end

    it "saving the node should create all the nested nodes" do
      icecream = IceCream.new(:flavour => 'vanilla')
      suger  = Ingredience.new :name => 'suger'
      butter = Ingredience.new :name => 'butter'

      icecream.ingrediences << suger << butter
      icecream.ingrediences.should include(suger, butter)

      suger.neo_id.should == nil
      icecream.save.should be_true

      # then
      suger.neo_id.should_not be_nil
      icecream.ingrediences.should include(suger, butter)
      icecream.outgoing(:ingrediences).should include(suger, butter)

      # make sure the nested nodes were properly saved
      ice = IceCream.load(icecream.neo_id)
      ice.ingrediences.should include(suger, butter)
      ice.outgoing(:ingrediences).should include(suger, butter)
    end

    it "should not save nested nodes if it was not valid" do
      icecream = IceCream.new # not valid
      suger  = Ingredience.new :name => 'suger'
      butter = Ingredience.new :name => 'butter'

      icecream.ingrediences << suger << butter
      icecream.ingrediences.should include(suger, butter)

      suger.neo_id.should == nil
      icecream.save.should be_false

      # then
      icecream.ingrediences.should include(suger, butter)
      icecream.outgoing(:ingrediences).should include(suger, butter)

      suger.neo_id.should == nil
   end

  end
end
