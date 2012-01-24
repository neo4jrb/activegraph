require File.join(File.dirname(__FILE__), '..', 'spec_helper')

# Specs written by Nick Sieger and modified by Andreas Ronge

describe Neo4j::Model do
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

    it "validation is skipped if save(:validate => false)" do
      v = IceCream.new(:name => 'illegal')
      v.save(:validate => false).should be_true
      v.should be_persisted
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


  describe "transaction" do
    it "runs a block in a transaction" do
      id = IceCream.transaction do
        a = IceCream.create :flavour => 'vanilla'
        a.ingredients << Neo4j::Node.new
        a.id
      end
      IceCream.load(id).should_not be_nil
    end

    it "takes a 'tx' parameter that can be used to rollback the transaction" do
      id = IceCream.transaction do |tx|
        a = IceCream.create :flavour => 'vanilla'
        a.ingredients << Neo4j::Node.new
        tx.fail
        a.id
      end
      IceCream.load(id).should be_nil
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
      model = IceCream.new
      model.flavour = "vanilla"
      model.save
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
        model.flavour = "horse"
        model.should be_valid
        model.save

        model.flavour = nil
        model.flavour.should be_nil
        model.should_not be_valid
        model.save
      end

      model.reload.flavour.should == 'vanilla'
    end

    it "does not modify relationships if validation fails when save is run in a transaction" do
      model = IceCream.create(:flavour => 'vanilla')
      model.ingredients << Ingredient.create(:name => 'sugar')
      model.save

      IceCream.transaction do
        model.flavour = nil
        model.ingredients << Ingredient.create(:name => 'flour')
        model.save.should be_false
      end

      model.reload.flavour.should == 'vanilla'
      model.ingredients.size.should == 1
      model.ingredients.first.name.should == 'sugar'
    end

    it "create can initialize the object with a block" do
      model = IceCream.create! {|o| o.flavour = 'vanilla'}
      model.should be_persisted
      model.flavour = 'vanilla'

      model = IceCream.create {|o| o.flavour = 'vanilla'}
      model.should be_persisted
      model.flavour = 'vanilla'
    end

    it "should save successfully when model is ::Property" do
      class ::Property < Neo4j::Rails::Model
      end
      ::Property.new.save.should be_true
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
      p.flavour_changed?.should == true
      p.flavour_change.should == [nil, 'kalle']
      p.flavour_was.should == nil
      p.flavour_changed?.should be_true
      p.flavour_was.should == nil
      p.save!
      p.flavour = 'andreas'
      p.flavour_change.should == ['kalle', 'andreas']
      p.save
      p.should_not be_changed
    end
  end

  describe "find" do
    class ReferenceNode < Neo4j::Rails::Model
      property :name
      index :name
    end

    after(:each) do
      Neo4j.threadlocal_ref_node = nil
    end

    it "should load all nodes of that type from the database" do
      model = IceCream.create :flavour => 'vanilla'
      IceCream.all.should include(model)
    end

    it "should allow switching the reference node" do
      reference = ReferenceNode.create(:name => 'Name')
      Neo4j.threadlocal_ref_node = reference
      icecream = IceCream.create(:flavour => 'vanilla')
      IceCream.first.should == icecream
    end

    it "switching the reference node should change the scope of finder queries" do
      reference1 = ReferenceNode.create(:name => 'Ref1')
      reference2 = ReferenceNode.create(:name => 'Ref2')
      Neo4j.threadlocal_ref_node = reference1
      icecream_for_reference1 = IceCream.create(:flavour => 'vanilla')
      IceCream.all.size.should == 1
      IceCream.first.should == icecream_for_reference1
      Neo4j.threadlocal_ref_node = reference2
      icecream_for_reference2 = IceCream.create(:flavour => 'strawberry')
      IceCream.all.size.should == 1
      IceCream.first.should == icecream_for_reference2
    end

    it "switching the reference node works for multiple entities" do
      reference1 = ReferenceNode.create(:name => 'Ref1')
      reference2 = ReferenceNode.create(:name => 'Ref2')
      Neo4j.threadlocal_ref_node = reference1
      icecream_for_reference1 = IceCream.create(:flavour => 'vanilla')
      ingredient_for_reference_1 = Ingredient.create(:name => 'sugar')
      IceCream.all.size.should == 1
      IceCream.first.should == icecream_for_reference1
      Ingredient.all.size.should == 1
      Ingredient.first.should == ingredient_for_reference_1
      Neo4j.threadlocal_ref_node = reference2
      icecream_for_reference2 = IceCream.create(:flavour => 'strawberry')
      ingredient_for_reference_2 = Ingredient.create(:name => 'eggs')
      IceCream.all.size.should == 1
      IceCream.first.should == icecream_for_reference2
      Ingredient.all.size.should == 1
      Ingredient.first.should == ingredient_for_reference_2
    end

    it "should find the node given it's id" do
      model = IceCream.create(:flavour => 'thing')
      IceCream.find(model.neo_id.to_s).should == model
    end


    it "should find a model by one of its attributes" do
      model = IceCream.create(:flavour => 'vanilla')
      IceCream.find("flavour: vanilla").should == model
    end

    it "should only find two by same attribute" do
      m1 = IceCream.create(:flavour => 'vanilla')
      m2 = IceCream.create(:flavour => 'vanilla')
      m3 = IceCream.create(:flavour => 'fish')
      IceCream.all("flavour: vanilla").size.should == 2
    end

    context "when node is attached to default ref node" do
      let(:reference1) { ReferenceNode.create(:name => 'Ref1') }
      let(:reference2) { ReferenceNode.create(:name => 'Ref2') }

      class IndexedGlobalModel < Neo4j::Model
        property :name
        index :name
        ref_node { Neo4j.default_ref_node }
      end

      context "given node is created with threadlocal node set" do
        before(:each) do
          Neo4j.threadlocal_ref_node = reference1
          @model = IndexedGlobalModel.create!(:name => 'foo')
        end

        it "should find the model when threadlocal node is set" do
          Neo4j.threadlocal_ref_node = reference2

          IndexedGlobalModel.find(:name => 'foo').should == @model
        end

        it "should find the node when threadlocal node is not set" do
          Neo4j.threadlocal_ref_node = nil

          IndexedGlobalModel.find(:name => 'foo').should == @model
        end
      end

      context "given node is created with threadlocal node set" do
        before(:each) do
          Neo4j.threadlocal_ref_node = nil
          @model = IndexedGlobalModel.create!(:name => 'foo')
        end

        it "should find the node when threadlocal node is not set" do
          Neo4j.threadlocal_ref_node = nil

          IndexedGlobalModel.find(:name => 'foo').should == @model
        end

        it "should find the model when threadlocal node is set" do
          Neo4j.threadlocal_ref_node = reference1

          IndexedGlobalModel.find(:name => 'foo').should == @model
        end
      end
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
      class RunBeforeAndAfterCreateCallbackModel < Neo4j::Rails::Model
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
        end
      end
      model = RunBeforeAndAfterCreateCallbackModel.create!
      model.created.should_not be_nil
      model.saved.should_not be_nil
    end

    it "should run before and after save callbacks" do
      class RunBeforeAndAfterSaveCallbackModel < Neo4j::Rails::Model
        property :created
        before_save :timestamp

        def timestamp
          self.created = "yes"
          fail "Expected new record" unless new_record?
        end

        after_save :mark_saved
        attr_reader :saved

        def mark_saved
          @saved = true
        end
      end

      model = RunBeforeAndAfterSaveCallbackModel.create!
      model.created.should_not be_nil
      model.saved.should_not be_nil
    end

    it "should run before and after new & save callbacks" do
      class RunBeforeAndAfterNewAndSaveCallbackModel < Neo4j::Rails::Model
        property :created
        before_save :timestamp

        def timestamp
          self.created = "yes"
          fail "Expected new record" unless new_record?
        end

        after_save :mark_saved
        attr_reader :saved

        def mark_saved
          @saved = true
        end
      end

      model = RunBeforeAndAfterNewAndSaveCallbackModel.new
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
      class UpdatedAttributesModel < Neo4j::Rails::Model
        property :name
        validates_presence_of :name
      end
      model = UpdatedAttributesModel.create!(:name => "vanilla")
      model.update_attributes(:name => nil).should be_false
      model.reload.name.should == "vanilla"
    end
  end

  context "transactionality" do
    let(:clazz) do
      create_model do
        has_one :icecream
        validates_presence_of :icecream
      end
    end

    describe "update_attributes!" do
      it "should not update the relations when model is invalid" do
        model = clazz.create!(:icecream => IceCream.create!(:flavour => 'x'))

        begin
          model.update_attributes!(:icecream => nil)
        rescue Neo4j::Model::RecordInvalidError
        end

        model.reload.icecream.should_not be_nil
      end
    end

    describe "update_attributes" do
      it "should not update the relations when model is invalid" do
        model = clazz.create!(:icecream => IceCream.create!(:flavour => 'x'))

        model.update_attributes(:icecream => nil)

        model.reload.icecream.should_not be_nil
      end
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

        # rollback the transaction
        Neo4j::Rails::Transaction.fail
      end

      cream.should_not exist
    end

    it "should roll back a transaction when the transaction fails within a nested transaction" do
      cream = nil
      IceCream.transaction do
        cream = IceCream.create :flavour => 'x'
        cream.flavour = 'vanilla'
        cream.should exist
        Ingredient.transaction do
          ingredient = Ingredient.create(:name => 'sugar')
          cream.ingredients << ingredient

          # rollback the transaction
          Neo4j::Rails::Transaction.fail
        end
      end

      cream.should_not exist
    end

    it "should commit a two level nested transaction" do
      cream = nil
      IceCream.transaction do
        cream = IceCream.create :flavour => 'x'
        cream.flavour = 'vanilla'
        cream.should exist
        Ingredient.transaction do
          ingredient = Ingredient.create(:name => 'sugar')
          cream.ingredients << ingredient
        end
      end

      cream.should exist
      cream.flavour.should == 'vanilla'
      cream.ingredients.size.should == 1
      cream.ingredients.first.name.should == 'sugar'
    end
  end

  describe "Neo4j::Rails::Validations::UniquenessValidator" do
    before(:all) do
      class ValidThing < Neo4j::Model
        index :email
        validates :email, :uniqueness => true
      end
      @klass = ValidThing
    end

    it "have correct kind" do
      Neo4j::Rails::Validations::UniquenessValidator.kind.should == :uniqueness
    end
    it "should not allow to create two nodes with unique fields" do
      a = @klass.create(:email => 'abc@se.com')
      b = @klass.new(:email => 'abc@se.com')

      b.save.should be_false
      b.errors.size.should == 1
    end

    it "should allow to create two nodes with not unique fields" do
      @klass.create(:email => 'abc@gmail.copm')
      b = @klass.new(:email => 'ab@gmail.com')

      b.save.should_not be_false
      b.errors.size.should == 0
    end

  end

  describe "attr_accessible" do
    before(:all) do
      @klass = create_model do
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

  describe "has_one, has_n, incoming" do
    before(:all) do
      item = create_model do
        property :name
        validates :name, :presence => true
        def to_s
          "Item #{name} class: #{self.class} id: #{self.object_id}"
        end
      end

      @order = create_model do
        property :name
        has_n(:items).to(item)
        validates :name, :presence => true
        def to_s
          "Order #{name} class: #{self.class} id: #{self.object_id}"
        end
      end

      @item = item # used as closure
      @item.has_n(:orders).from(@order, :items)
    end

    it "add nodes without save should only store it in memory" do
      order = @order.new :name => 'order'
      item =  @item.new :name => 'item'

      # then
      item.orders << order
      item.orders.should include(order)
      Neo4j.all_nodes.should_not include(item)
      Neo4j.all_nodes.should_not include(order)
    end

    it "add nodes with save should store it in db" do
      order = @order.new :name => 'order'
      item  = @item.new :name => 'item'

      # then
      item.orders << order
      item.orders.should include(order)
      item.save
      Neo4j.all_nodes.should include(item)
      Neo4j.all_nodes.should include(order)
      item.reload
      item.orders.should include(order)
    end
  end

  describe "i18n_scope" do
    subject { Neo4j::Rails::Model.i18n_scope }
    it { should == :neo4j }
  end

  describe "reachable_from_ref_node?" do
    let(:ref_1) { Neo4j::Rails::Model.create!(:name => "Ref1") }
    let(:ref_2) { Neo4j::Rails::Model.create!(:name => "Ref2") }

    context "when node is not attached to default ref node" do
      before(:each) do
        Neo4j.threadlocal_ref_node = ref_1
        @node_from_ref_1 = IceCream.create!(:flavour => 'Vanilla')
      end

      after(:each) do
        Neo4j.threadlocal_ref_node = nil
      end

      context "when node is created under current threadlocal ref_node" do
        it "should be true" do
          Neo4j.threadlocal_ref_node = ref_1

          @node_from_ref_1.should be_reachable_from_ref_node
        end
      end

      context "when node is not created under current threadlocal ref_node" do
        it "should be false" do
          Neo4j.threadlocal_ref_node = ref_2

          @node_from_ref_1.should_not be_reachable_from_ref_node
        end
      end
    end

    context "when node is attached to default ref node" do
      let(:clazz) do
        create_model do
           ref_node { Neo4j.default_ref_node }
        end
      end

      context "when threadlocal node is set" do
        it "should be true" do
          Neo4j.threadlocal_ref_node = ref_1
          node = clazz.create!

          node.should be_reachable_from_ref_node
        end
      end

      context "when threadlocal node is not set" do
        it "should be true" do
          Neo4j.threadlocal_ref_node = nil
          node = clazz.create!

          node.should be_reachable_from_ref_node
        end
      end
    end
  end

  describe "#columns" do
    context "a model with no defined properties" do
      it "should return an empty array" do
        create_model.columns.should be_empty
      end
    end

    context "a model with two defined property" do
      it "should return an empty array" do
        columns = create_model do
          property :foo
          property :bar
        end.columns
        columns.size.should == 2
        columns.should include(:foo, :bar)
      end
    end

  end
end
