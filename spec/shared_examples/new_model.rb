shared_examples 'new model' do

  context "when unsaved" do
    it { should_not be_persisted }

    it "should not allow write access to undeclared properties" do
      expect { subject[:unknown] = "none" }.to raise_error(ActiveAttr::UnknownAttributeError)
    end

    it "should not allow read access to undeclared properties" do
      subject[:unknown].should be_nil
    end

    it "should allow access to all properties before it is saved" do
      subject.props.should be_a(Hash)
    end

    it "should allow properties to be accessed with a symbol" do
      lambda { subject.props[:test] = true }.should_not raise_error
    end
  end

end
