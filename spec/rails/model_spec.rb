require File.join(File.dirname(__FILE__), '..', 'spec_helper')

# Specs written by Nick Sieger and modified by Andreas Ronge

class IceCream < Neo4j::Model
  property :flavour
  index :flavour
  rule(:all)
  validates_presence_of :flavour
end

describe Neo4j::Model, :type => :transactional do

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

    it "should fail to save new model without a transaction" do
      finish_tx
      expect { @model.save }.to raise_error
    end

    it "validation is performed" do
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


    it "save should create a new node when run in a transaction" do
      v = ActivePerson.new(:flavour => 'q')
      v.save
      new_tx
      Neo4j::Node.should exist(v)
    end

    it "has nil as id befored saved" do
      v = ActivePerson.new(:name => 'andreas')
      v.neo_id.should == nil
    end

  end

  describe "load" do
    before :each do
      @model = Neo4j::Model.create
      @model.save
    end

    it "should load a previously stored node" do
      result = Neo4j::Model.load(@model.id)
      result.should == @model
      result.should be_persisted
    end
  end


  describe "save" do
    it "should store the model in the database" do
      model = IceCream.new
      model.flavour = "vanilla"
      model.save
      model.should be_persisted
      IceCream.load(model.id).should == model
      finish_tx
    end

    it "should not save the model if it is invalid" do
      model = IceCream.new
      model.save.should_not be_true
      model.should_not be_valid

      model.should_not be_persisted
      model.id.should be_nil
    end

    it "validates the model and return true if it was valid" do
      model = IceCream.create
      model.save.should be_false
    end


    it "the validation method 'errors' returns the validation errors" do
      p = IceCream.create
      p.should_not be_valid
      p.errors.keys[0].should == :flavour
      p.flavour = 'vanilla'
      p.should be_valid
      p.errors.size.should == 0
    end


    it "implements the ActiveModel::Dirty interface" do
      p = ActivePerson.create
      p.should_not be_changed
      p.name = 'kalle'
      p.should be_changed
      p.attribute_changed?('name').should == true
      p.name_change.should == [nil, 'kalle']
      p.name_was.should == nil
      p.name_changed?.should be_true
      p.name_was.should == nil

      p.name = 'andreas'
      p.name_change.should == ['kalle', 'andreas']
      p.save
      p.should_not be_changed
    end

  end

  describe "find" do

    it "should load all nodes of that type from the database" do
      model = IceCream.create :flavour => 'vanilla'
      finish_tx
      IceCream.all.should include(model)
    end

    it "should find the node given it's id" do
      model = IceCream.create
      IceCream.find(model.neo_id.to_s).should == model
    end


    it "should find a model by one of its attributes" do
      model = IceCream.create
      model.flavour = "vanilla"
      finish_tx
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
      new_tx
      Neo4j::Node.load(id).should be_nil
    end
  end

  describe "create" do
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

    it "should run before and after create callbacks" do
      klass = model_subclass do
        property :created
        before_create :timestamp

        def timestamp
          self.created = "yes"
        end

        after_create :mark_saved
        attr_reader :saved

        def mark_saved
          @saved = true
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
        end

        after_save :mark_saved
        attr_reader :saved

        def mark_saved
          @saved = true
        end
      end
      model = klass.create!
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
      pending "reload not implemented yet"
      klass = model_subclass do
        property :name
        validates_presence_of :name
      end
      model = klass.create!(:name => "vanilla")
      model.update_attributes(:name => nil).should be_false
      model.reload.name.should == "vanilla"
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

end