# rubocop:disable Metrics/ModuleLength
# Originally part of ActiveAttr, https://github.com/cgriego/active_attr
module Neo4j::Shared
  describe Attributes do
    subject(:model) { model_class.new }
    let(:last_name) { 'Poweski' }

    let :model_class do
      Class.new do
        include Property
        include Attributes
        property :first_name
        property :last_name
        property :amount

        def self.name
          'Foo'
        end

        def amount
          super
        end

        def amount=(*)
          super
        end

        def last_name=(value)
          super(value.to_s.upcase)
        end

        def last_name
          super || 'Poweski'
        end

        def initialize(first_name = nil)
          super()
          write_attribute(:first_name, first_name)
        end
      end
    end

    let :attributeless do
      Class.new.tap do |attributeless|
        attributeless.class_eval do
          include Property
          include Attributes

          def self.name
            'Foo'
          end
        end
      end
    end

    describe '.property' do
      context 'a dangerous attribute' do
        before { allow(model_class).to receive(:dangerous_attribute?).and_return(true) }

        it { expect { model_class.property(:address) }.to raise_error Neo4j::DangerousAttributeError }
      end

      context 'a harmless attribute' do
        it 'creates an attribute with no options' do
          expect(model_class.attributes.values).to include(DeclaredProperty.new(:first_name))
        end

        it 'returns the attribute definition' do
          expect(model_class.property(:address) == DeclaredProperty.new(:address)).to eq true
        end

        it 'defines an attribute reader that calls #attribute' do
          expect(model).to receive(:attribute).with('first_name')
          model.first_name
        end

        it 'defines an attribute reader that can be called via super' do
          expect(model).to receive(:attribute).with('amount')
          model.amount
        end

        it 'defines an attribute writer that calls #attribute=' do
          expect(model).to receive(:attribute=).with('first_name', 'Ben')
          model.first_name = 'Ben'
        end

        it 'defines an attribute writer that can be called via super' do
          expect(model).to receive(:attribute=).with('amount', 1)
          model.amount = 1
        end

        it 'defining an attribute twice does not give the class two attribute definitions' do
          expect(
            Class.new do
              include Property
              include Attributes
              property :name
              property :name
            end.attributes.size).to eq 1
        end
      end
    end

    describe '.attributes' do
      it { expect(model_class).to respond_to(:attributes) }

      it 'can access AttributeDefinition with a Symbol' do
        expect(model_class.attributes[:first_name]).to eq DeclaredProperty.new(:first_name)
      end

      it 'can access AttributeDefinition with a String' do
        expect(model_class.attributes['first_name']).to eq DeclaredProperty.new(:first_name)
      end

      context 'when no attributes exist' do
        it { expect(attributeless.attributes).to be_empty }
      end
    end

    describe '#==' do
      subject { model_class.new('Ben') }

      it 'returns true when all attributes are equal' do
        is_expected.to eq model_class.new('Ben')
      end

      it 'returns false when compared to another type' do
        is_expected.not_to eq Struct.new(:attributes).new('first_name' => 'Ben')
      end
    end

    describe '#attributes' do
      context 'when no attributes are defined' do
        it 'returns an empty Hash' do
          expect(attributeless.new.attributes).to eq({})
        end
      end

      context 'when an attribute is defined' do
        it 'returns the key value pairs' do
          model.first_name = 'Ben'
          expect(model.attributes).to include('first_name' => 'Ben')
        end

        it 'returns a new Hash ' do
          model.attributes.merge!('first_name' => 'Bob')
          expect(model.attributes).not_to include('first_name' => 'Bob')
        end

        it 'returns all attributes' do
          expect(model.attributes.keys.sort).to eq %w(amount first_name last_name)
        end
      end

      context 'when a getter is overridden' do
        it 'uses the overridden implementation' do
          expect(model.attributes).to include('last_name' => last_name)
        end
      end
    end

    [:[], :read_attribute].each do |method|
      describe "##{method}" do
        context 'when an attribute is not set' do
          it 'returns nil' do
            expect(model.send(method, :first_name)).to be_nil
          end
        end

        context 'when an attribute is set' do
          let(:first_name) { 'Bob' }

          before { model.write_attribute(:first_name, first_name) }

          it 'returns the attribute using a Symbol' do
            expect(model.send(method, :first_name)).to eq(first_name)
          end

          it 'returns the attribute using a String' do
            expect(model.send(method, 'first_name')).to eq(first_name)
          end
        end

        context 'when the getter is overridden' do
          it 'uses the overridden implementation' do
            expect(model.send(method, :last_name)).to eq(last_name)
          end
        end

        it 'returns nil when getting an undefined attribute' do
          expect(model.send(method, :initials)).to be_nil
        end
      end
    end

    [:[]=, :write_attribute].each do |method|
      describe "##{method}" do
        it 'raises ArgumentError with one argument' do
          expect { model.send(method, :first_name) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError with no arguments' do
          expect { model.send(method) }.to raise_error(ArgumentError)
        end

        it 'sets an attribute using a Symbol and value' do
          expect { model.send(method, :first_name, 'Ben') }.to change { model.attributes['first_name'] }.from(nil).to('Ben')
        end

        it 'sets an attribute using a String and value' do
          expect { model.send(method, 'first_name', 'Ben') }.to change { model.attributes['first_name'] }.from(nil).to('Ben')
        end

        it 'is able to set an attribute to nil' do
          model.first_name = 'Ben'
          expect { model.send(method, :first_name, nil) }.to change { model.attributes['first_name'] }.from('Ben').to(nil)
        end

        it 'uses the overridden implementation when the setter is overridden' do
          expect(model.send(method, :last_name, 'poweski')).to eq('POWESKI')
        end

        it 'raises when setting an undefined attribute' do
          expect do
            model.send(method, :initials, 'BP')
          end.to raise_error Neo4j::UnknownAttributeError, 'unknown attribute: initials'
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
