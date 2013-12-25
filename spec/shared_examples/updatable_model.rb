share_examples_for "updatable model" do
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