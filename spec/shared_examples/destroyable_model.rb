shared_examples_for 'destroyable model' do
  context 'when saved' do
    before :each do
      subject.save!
      @other = subject.class.find_by_id(subject.id)
      @old_id = subject.id
      subject.destroy
    end
    it { is_expected.to be_frozen }

    it 'should remove the model from the database' do
      expect(subject.class.find_by_id(@old_id)).to be_nil
    end
  end
end
