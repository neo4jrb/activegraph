shared_examples_for 'creatable model' do
  context 'when attempting to create' do

    it 'should create ok' do
      subject.class.create(subject.attributes).should be_truthy
    end

    it 'should not raise an exception on #create!' do
      lambda { subject.class.create!(subject.attributes) }.should_not raise_error
    end

    it 'should save the model and return it' do
      model = subject.class.create(subject.attributes)
      model.should be_persisted
    end

    it 'should accept attributes to be set' do
      model = subject.class.create(subject.attributes.merge(name: 'Ben'))
      model[:name].should == 'Ben'
    end
  end
end
