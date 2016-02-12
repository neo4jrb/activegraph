shared_examples_for 'updatable model' do
  context 'when saved' do
    before { subject.save! }

    context 'and updated' do
      it 'should have altered attributes' do
        expect { subject.update!(a: 1, b: 2) }.not_to raise_error
        expect(subject[:a]).to eq(1)
        expect(subject[:b]).to eq(2)
      end
    end
  end
end
