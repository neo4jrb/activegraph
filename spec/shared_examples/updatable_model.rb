shared_examples_for 'updatable model' do
  context 'when saved' do
    before { subject.save! }

    context 'and updated' do
      it 'should have altered attributes' do
        lambda { subject.update!(a: 1, b: 2) }.should_not raise_error
        subject[:a].should eq(1)
        subject[:b].should eq(2)
      end
    end
  end

end
