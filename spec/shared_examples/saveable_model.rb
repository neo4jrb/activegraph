shared_examples 'saveable model' do
  context "when attempting to save" do
    it "should save ok" do
      subject.save.should be_true
    end

    it "should save without raising an exception" do
      expect{ subject.save! }.to_not raise_error
    end

    context "after save" do
      before(:each) { subject.save }

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
    it { should == subject.class.load_entity(subject.id) }
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

  end
end
