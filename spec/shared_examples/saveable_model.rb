shared_examples 'saveable model' do
  context 'when attempting to save' do
    it 'should save ok' do
      expect(subject.save).to be true
    end

    it 'should save without raising an exception' do
      expect { subject.save! }.to_not raise_error
    end

    context 'after save' do
      before(:each) { subject.save }

      it { is_expected.to be_valid }

      it { is_expected.to eq(subject.class.find(subject.id.to_s)) }

      it 'should be included in all' do
        expect(subject.class.all.to_a).to include(subject)
      end
    end
  end

  context 'after being saved' do
    # make sure it looks like an ActiveModel model
    include ActiveModel::Lint::Tests

    before :each do
      subject.save
    end

    it { is_expected.to be_persisted }
    it { is_expected.to eq(subject.class.find_by_id(subject.id)) }
    it { is_expected.to be_valid }

    it 'should be found in the database' do
      expect(subject.class.all.to_a).to include(subject)
    end

    it { is_expected.to respond_to(:to_param) }

    # it "should respond to primary_key" do
    #  subject.class.should respond_to(:primary_key)
    # end

    it 'should render as XML' do
      expect(subject.to_xml).to match(/^<\?xml version=/) if subject.respond_to?(:to_xml)
    end
  end
end
