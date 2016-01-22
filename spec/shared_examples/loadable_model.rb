shared_examples 'loadable model' do
  context 'when saved' do
    before :each do
      subject.save
    end

    it 'should load_entity a previously stored node' do
      result = subject.class.find(subject.id)
      expect(result).to eq(subject)
      expect(result).to be_persisted
    end
  end
end
