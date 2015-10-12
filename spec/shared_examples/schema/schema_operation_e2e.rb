shared_examples 'schema operation create/drop' do |clazz, incompatible_clazz|
  before(:all) do
    l = Neo4j::Label.create(:MyLabel)
    l.drop_constraint(:name, type: :unique) if Neo4j::Label.constraint?(:MyLabel, :name)
    l.drop_index(:name) if Neo4j::Label.index?(:MyLabel, :name)
  end

  let(:label) { 'MyLabel' }
  let(:property) { 'name' }
  let(:instance) { clazz.new(label, property) }

  describe '#create!' do
    it do
      expect(instance).to receive(:drop_incompatible!).and_call_original
      expect { instance.create! }.to change { instance.exist? }.from(false).to(true)
    end
  end

  describe '#drop!' do
    before { instance.create! unless instance.exist? }
    it do
      expect { instance.drop! }.to change { instance.exist? }.from(true).to(false)
    end
  end

  describe '#drop_incompatible!' do
    let(:incompatible_instance) { incompatible_clazz.new(label, property) }

    before do
      instance.drop! if instance.exist?
      incompatible_clazz.new(label, property).create!
    end

    it { expect { instance.drop_incompatible! }.to change { incompatible_instance.exist? }.from(true).to(false) }
  end
end
