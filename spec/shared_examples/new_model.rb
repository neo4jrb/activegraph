shared_examples 'new model' do
  context 'when unsaved' do
    it { is_expected.not_to be_persisted }

    it 'should not allow write access to undeclared properties' do
      expect { subject[:unknown] = 'none' }.to raise_error(Neo4j::UnknownAttributeError)
    end

    it 'should not allow read access to undeclared properties' do
      expect(subject[:unknown]).to be_nil
    end

    it 'should allow access to all properties before it is saved' do
      expect(subject.props).to be_a(Hash)
    end

    it 'should allow properties to be accessed with a symbol' do
      expect { subject.props[:test] = true }.not_to raise_error
    end
  end
end
