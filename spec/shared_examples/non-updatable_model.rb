shared_examples_for "non-updatable model" do
  context "then" do
    it "shouldn't update" do
      subject.update(a: 3).should_not be true
    end
  end
end
