shared_examples 'schema operation interface' do |instance|
  describe 'public interface' do
    subject { instance }
    it { is_expected.to respond_to(:create!) }
    it { is_expected.to respond_to(:label_object) }
    it { is_expected.to respond_to(:drop!) }
    it { is_expected.to respond_to(:drop_incompatible!) }
    it { is_expected.to respond_to(:exist?) }
    it { is_expected.to respond_to(:default_options) }
    it { is_expected.to respond_to(:type) }
    it { is_expected.to respond_to(:incompatible_operation_classes) }
  end

  describe '#drop_incompatible!' do
    describe 'drop_incompatible!' do
      it 'checks presence, drops when found' do
        instance.class.incompatible_operation_classes.each do |c|
          expect_any_instance_of(c).to receive(:exist?).and_return true
          expect_any_instance_of(c).to receive(:drop!)
        end

        instance.drop_incompatible!
      end
    end
  end
end
