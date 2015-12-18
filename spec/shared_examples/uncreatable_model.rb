shared_examples_for 'uncreatable model' do
  context 'when attempting to create' do
    it "shouldn't create ok" do
      expect(subject.class.create(subject.attributes).persisted?).not_to be true
    end

    it 'should raise an exception on #create!' do
      expect { subject.class.create!(subject.attributes) }.to raise_error Neo4j::ActiveNode::Persistence::RecordInvalidError
    end
  end
end
