require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/date_time/calculations'

share_examples_for "a new model" do
  context "when unsaved" do
    it { should_not be_persisted }

    it "should allow direct access to properties before it is saved" do
      subject["fur"] = "none"
      subject["fur"].should == "none"
    end

    it "should allow access to all properties before it is saved" do
      subject.props.should be_a(Hash)
    end

    it "should allow properties to be accessed with a symbol" do
      lambda{ subject.props[:test] = true }.should_not raise_error
    end
  end
end

share_examples_for "a loadable model" do
  context "when saved" do
    before :each do
      subject.save!
    end

    it "should load a previously stored node" do
      result = subject.class.load(subject.id)
      result.should == subject
      result.should be_persisted
    end
  end
end

share_examples_for "a saveable model" do
  context "when attempting to save" do
    it "should save ok" do
      subject.save.should be_true
    end

    it "should save without raising an exception" do
      subject.save!.should_not raise_error(org.neo4j.graphdb.NotInTransactionException)
    end

    context "after save" do
      before(:each) { subject.save}

      it { should be_valid }

      it { should == subject.class.find(subject.id.to_s) }
      it "should be included in all" do
        subject.class.all.to_a.should include(subject)
      end
    end
  end

  context "after being saved" do
    # make sure it looks like an ActiveModel model
    include ActiveModel::Lint::Tests

    before :each do
      subject.save
    end

    it { should be_persisted }
    it { should == subject.class.load(subject.id) }
    it { should be_valid }

    it "should be found in the database" do
      subject.class.all.to_a.should include(subject)
    end

    it { should respond_to(:to_param) }

    #it "should respond to primary_key" do
    #  subject.class.should respond_to(:primary_key)
    #end

    it "should render as XML" do
      subject.to_xml.should =~ /^<\?xml version=/
    end

    context "attributes" do
      before(:each) do
        @original_subject = @original_subject.attributes
      end

      it { should_not include("_neo-id") }
      it { should_not include("_classname") }
    end
  end
end

share_examples_for "an unsaveable model" do
  context "when attempting to save" do
    it "should not save ok" do
      subject.save.should_not be_true
    end

    it "should raise an exception" do
      lambda { subject.save! }.should raise_error
    end
  end

  context "after attempted save" do
    before { subject.save }

    it { should_not be_persisted }

    it "should have a nil id after save" do
      subject.id.should be_nil
    end
  end

  context "without validation" do
  	it "should save ok" do
  		subject.save(:validate => false).should == true
  	end

  	it "shouldn't cause an exception while saving" do
  		lambda { subject.save!(:validate => false) }.should_not raise_error
  	end
  end
end

share_examples_for "a destroyable model" do
  context "when saved" do
    before :each do
      subject.save!
      @other = subject.class.load(subject.id)
      subject.destroy
    end
    it { should be_frozen }

    it "should remove the model from the database" do
      subject.class.load(subject.id).should be_nil
    end

    it "should also be frozen in @other" do
    	@other.should be_frozen
    end
  end
end

share_examples_for "a creatable model" do
  context "when attempting to create" do

    it "should create ok" do
      subject.class.create(subject.attributes).should be_true
    end

    it "should not raise an exception on #create!" do
      lambda { subject.class.create!(subject.attributes) }.should_not raise_error
    end

    it "should save the model and return it" do
      model = subject.class.create(subject.attributes)
      model.should be_persisted
    end

    it "should accept attributes to be set" do
      model = subject.class.create(subject.attributes.merge(:name => "Ben"))
      model[:name].should == "Ben"
    end
  end
end

share_examples_for "a creatable relationship model" do
  context "when attempting to create" do

    it "should create ok" do
      subject.class.create(:some_type, @start_node, @end_node, subject.attributes).should be_true
    end

    it "should not raise an exception on #create!" do
      lambda { subject.class.create!(:some_type, @start_node, @end_node, subject.attributes) }.should_not raise_error
    end

    it "should save the model and return it" do
      model = subject.class.create(:some_type, @start_node, @end_node, subject.attributes)
      model.should be_persisted
    end

    it "should accept attributes to be set" do
      model = subject.class.create(:some_type, @start_node, @end_node, subject.attributes.merge(:name => "Ben"))
      model[:name].should == "Ben"
    end
  end
end

share_examples_for "an uncreatable model" do
  context "when attempting to create" do

    it "shouldn't create ok" do
      subject.class.create(subject.attributes).persisted?.should_not be_true
    end

    it "should raise an exception on #create!" do
      lambda { subject.class.create!(subject.attributes) }.should raise_error
    end
  end
end

share_examples_for "an uncreatable relationship model" do
  context "when attempting to create" do

    it "shouldn't create ok" do
      subject.class.create(subject.attributes).persisted?.should_not be_true
    end

    it "should raise an exception on #create!" do
      lambda { subject.class.create!(subject.attributes) }.should raise_error
    end
  end
end

share_examples_for "an updatable model" do
  context "when saved" do
    before { subject.save! }

    context "and updated" do
      it "should have altered attributes" do
        lambda { subject.update_attributes!(:a => 1, :b => 2) }.should_not raise_error
        subject[:a].should == 1
        subject[:b].should == 2
      end
    end
  end
end

share_examples_for "a non-updatable model" do
  context "then" do
    it "shouldn't update" do
      subject.update_attributes({ :a => 3 }).should_not be_true
    end
  end
end

share_examples_for "a timestamped model" do
	before do
		# stub these out so they return the same values all the time
		@time = Time.now
		@tomorrow = Time.now.tomorrow
		Time.stub!(:now).and_return(@time)
		subject.save!
	end

	it "should have set updated_at" do
		subject.updated_at.to_i.should == Time.now.to_i
	end

	it "should have set created_at" do
		subject.created_at.to_i == Time.now.to_i
	end

	context "when updated" do
    before(:each) do
    	Time.stub!(:now).and_return(@tomorrow)
    end

    it "created_at is not changed" do
      lambda { subject.update_attributes!(:a => 1, :b => 2) }.should_not change(subject, :created_at)
    end

    it "should have altered the updated_at property" do
      lambda { subject.update_attributes!(:a => 1, :b => 2) }.should change(subject, :updated_at)
    end

    context "without modifications" do
      it "should not alter the updated_at property" do
        lambda { subject.save! }.should_not change(subject, :updated_at)
      end
    end
  end
end

shared_examples_for "a relationship model" do

  context "with something" do
    before(:each) do
      subject[:something] = "test setting the property before the relationship is persisted"
    end

    context "before save" do
      it "should be persisted" do
        @start_node.should_not be_persisted
        @end_node.should_not be_persisted
        subject.should_not be_persisted
      end

      it "should still know about something" do
        subject[:something] == "test setting the property before the relationship is persisted"
      end

    end
    context "after save" do
      before(:each) do
        @start_node.save
      end

      #it { should be_a(RelationshipWithNoProperty) }
      it "should still know about something" do
        subject[:something] == "test setting the property before the relationship is persisted"
      end

      it "should be persisted" do
        @start_node.should be_persisted
        @end_node.should be_persisted
        subject.should be_persisted
      end
    end
  end
end
