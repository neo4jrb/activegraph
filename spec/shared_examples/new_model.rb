shared_examples 'new model' do

  context "when unsaved" do
    it { should_not be_persisted }

    it "should allow direct access to properties before it is saved" do
      subject[:name] = "none"
      subject[:name].should == "none"
    end

    it "should allow access to all properties before it is saved" do
      subject.props.should be_a(Hash)
    end

    it "should allow properties to be accessed with a symbol" do
      lambda{ subject.props[:test] = true }.should_not raise_error
    end
  end

end