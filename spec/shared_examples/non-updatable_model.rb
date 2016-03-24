shared_examples_for 'non-updatable model' do
  context 'then' do
    it "shouldn't update" do
      expect(subject.update(a: 3)).not_to be true
    end
  end
end
