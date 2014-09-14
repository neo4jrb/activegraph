shared_examples 'loadable model' do

  context "when saved" do
    before :each do
      subject.save
    end

    it "should find_by_id a previously stored node" do
      #puts "subject.id", subject.id
      result = subject.class.find(subject.id)
      result.should == subject
      result.should be_persisted
    end
  end

end
