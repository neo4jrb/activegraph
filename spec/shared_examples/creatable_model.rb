shared_examples_for 'creatable model' do
  context 'when attempting to create' do
    it 'should create ok' do
      expect(subject.class.create(subject.attributes)).to be_truthy
    end

    it 'should not raise an exception on #create!' do
      expect { subject.class.create!(subject.attributes) }.not_to raise_error
    end

    it 'should save the model and return it' do
      model = subject.class.create(subject.attributes)
      expect(model).to be_persisted
    end

    it 'should accept attributes to be set' do
      model = subject.class.create(subject.attributes.merge(name: 'Ben'))
      expect(model[:name]).to eq('Ben')
    end
  end
end
