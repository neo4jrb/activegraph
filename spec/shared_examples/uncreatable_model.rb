share_examples_for "uncreatable model" do
  context "when attempting to create" do

    it "shouldn't create ok" do
      subject.class.create(subject.attributes).persisted?.should_not be_true
    end

    it "should raise an exception on #create!" do
      lambda { subject.class.create!(subject.attributes) }.should raise_error
    end
  end
end
