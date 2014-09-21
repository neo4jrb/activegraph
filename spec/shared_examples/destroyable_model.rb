shared_examples_for "destroyable model" do
  context "when saved" do
    before :each do
      subject.save!
      @other = subject.class.find_by_id(subject.id)
      @old_id = subject.id
      subject.destroy
    end
    it { should be_frozen }

    it "should remove the model from the database" do
      subject.class.find_by_id(@old_id).should be_nil
    end

    it "should also be frozen in @other" do
      @other.should be_frozen
    end
  end
end
