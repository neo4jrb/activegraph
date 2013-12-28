share_examples_for "non-updatable model" do
  context "then" do
    it "shouldn't update" do
      subject.update_attributes({ :a => 3 }).should_not be_true
    end
  end
end
