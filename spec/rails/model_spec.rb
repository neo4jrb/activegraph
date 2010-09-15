require File.join(File.dirname(__FILE__), '..', 'spec_helper')

# Specs written by Nick Sieger and modified by Andreas Ronge

class IceCream < Neo4j::ActiveModel
  property :flavour
  index :flavour
  validates_presence_of :flavour
end

describe Neo4j::ActiveModel, "new"  do
  before :each do
    @model = Neo4j::ActiveModel.new
  end
  subject { @model }

  it { should_not be_persisted }

  it "should allow access to properties before it is saved" do
    @model["fur"] = "none"
    @model["fur"].should == "none"
  end

  it "should fail to save new model without a transaction" do
    lambda { @model.save }.should raise_error
  end
end

describe Neo4j::ActiveModel, "load", :type => :transactional do
  before :each do
      @model = Neo4j::ActiveModel.create
      @model.save
  end

  it "should load a previously stored node" do
    result = Neo4j::ActiveModel.load(@model.id)
    result.should == @model
    result.should be_persisted
  end
end


describe Neo4j::ActiveModel, "save", :type => :transactional do
  before :each do
    @model = IceCream.new
    @model.flavour = "vanilla"
  end

  it "should store the model in the database" do
    @model.save
    @model.should be_persisted
    IceCream.load(@model.id).should == @model
  end

  it "should not save the model if it is invalid" do
    @model = IceCream.new
    @model.save.should_not be_true
    @model.should_not be_valid

    puts "try persist"
    @model.should_not be_persisted
    @model.id.should be_nil
  end
end

describe Neo4j::ActiveModel, "find", :type => :transactional do
#  before :each do
#      @model = IceCream.new
#      @model.flavour = "vanilla"
#      @model.save
#  end
  #use_transactions

  it "should load all nodes of that type from the database" do
    pending
    IceCream.all.should include(@model)
  end

  it "should find a model by one of its attributes" do
    @model = IceCream.create
    @model.flavour = "vanilla"
    #@model.save

    Neo4j::Transaction.finish
    Neo4j::Transaction.new
    puts "--------------- FIND IT"
    IceCream.find(:flavour, "vanilla").to_a.should include(@model)
    puts "------------------ ?"
  end
end

describe Neo4j::ActiveModel, "lint", :type => :transactional do
  before :each do
    @model = Neo4j::ActiveModel.new
  end

  include  ActiveModel::Lint::Tests
end

describe Neo4j::ActiveModel, "destroy", :type => :transactional do
  before :each do
    @model = Neo4j::ActiveModel.create
  end

  it "should remove the model from the database" do
    id = @model.neo_id
    puts "DESTROY ? "
#    Neo4j::Transaction.new
    #Neo4j::Transaction.run { @model.destroy }
    @model.destroy
    Neo4j::Transaction.finish

    puts "---------- id: #{id} -"
    Neo4j::Transaction.new
    #Neo4j::Transaction.run { Neo4j::Node.load(id).should be_nil }
    Neo4j::Node.load(id).should be_nil
    Neo4j::Transaction.finish
  end
end

describe Neo4j::ActiveModel, "create", :type => :transactional do
  it "should save the model and return it" do
    model = Neo4j::ActiveModel.create
    model.should be_persisted
  end

  it "should accept attributes to be set" do
    puts "---XXXXXXXXX--------"
    model = Neo4j::ActiveModel.create :name => "Nick"
    model[:name].should == "Nick"
  end

  it "bang version should raise an exception if save returns false" do
    lambda { IceCream.create! }.should raise_error(Neo4j::ActiveModel::RecordInvalidError)
  end

  it "should run before and after create callbacks" do
    klass = model_subclass do
      property :created
      before_create :timestamp
      def timestamp
        puts "SET TIMESTAMP"
        self.created = "yes"
      end
      after_create :mark_saved
      attr_reader :saved
      def mark_saved
        @saved = true
      end
    end
    model = klass.create!
    puts "----------"
    model.created.should_not be_nil
    model.saved.should_not be_nil
  end
end

describe Neo4j::ActiveModel, "update_attributes", :type => :transactional do
  #insert_dummy_model
  it "should save the attributes" do
    model = Neo4j::ActiveModel.new
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
