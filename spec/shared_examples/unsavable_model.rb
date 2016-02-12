shared_examples_for 'unsaveable model' do
  context 'when attempting to save' do
    it 'should not save ok' do
      expect(subject.save).not_to be true
    end

    it 'should raise an exception' do
      expect { subject.save! }.to raise_error Neo4j::ActiveNode::Persistence::RecordInvalidError
    end
  end

  context 'after attempted save' do
    before { subject.save }

    it { is_expected.not_to be_persisted }

    it 'should have a nil id after save' do
      expect(subject.id).to be_nil
    end
  end

  context 'without validation' do
    it 'should save ok' do
      expect(subject.save(validate: false)).to eq(true)
    end

    it "shouldn't cause an exception while saving" do
      expect { subject.save!(validate: false) }.not_to raise_error
    end
  end
end
