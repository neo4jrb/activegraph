shared_examples_for "unsaveable model" do
  context "when attempting to save" do
    it "should not save ok" do
      subject.save.should_not be true
    end

    it "should raise an exception" do
      expect { subject.save! }.to raise_error
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
      subject.save(validate: false).should == true
    end

    it "shouldn't cause an exception while saving" do
      lambda { subject.save!(validate: false) }.should_not raise_error
    end
  end
end
