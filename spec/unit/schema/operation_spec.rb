module Neo4j::Schema
  describe 'Operation classes' do
    let(:label_double) { double('An instance of Neo4j::Label') }
    before { allow(Neo4j::Label).to receive(:create).and_return(label_double) }

    describe 'public interface' do
      [Operation, ExactIndexOperation, UniqueConstraintOperation].each do |c|
        instance = c.new('label', 'property')
        it_behaves_like 'schema operation interface', instance
      end
    end

    describe 'methods provided by base' do
      let(:instance) { Operation.new('label', 'property') }

      describe '#create!' do
        it 'drops incompatible, creates' do
          expect(instance).to receive(:drop_incompatible!)
          expect(instance).to receive(:exist?)
          expect(instance).to receive(:type).and_return('foo')
          expect(label_double).to receive(:send).with(:create_foo, :property, {})
          instance.create!
        end
      end

      describe '#drop!' do
        it 'sends the appropriate drop message to the label object based on its type' do
          expect(instance).to receive(:type).and_return('foo')
          expect(label_double).to receive(:send).with(:drop_foo, :property, {})
          instance.drop!
        end
      end
    end
  end
end
