# Originally part of ActiveAttr, https://github.com/cgriego/active_attr
# These tests were originally for the AttributeDefinition class.
# TODO: Additional unit tests for DeclaredProperty
module Neo4j::Shared
  describe DeclaredProperty do
    subject(:attribute_definition) { described_class.new(:amount, default: 'default') }

    describe '#<=>' do
      it "is nil if the right side is not an #{described_class}" do
        expect(attribute_definition <=> nil).to be_nil
      end

      it 'prefers neither when both sides use the same attribute name and options' do
        # rubocop:disable Lint/UselessComparison
        expect(attribute_definition <=> attribute_definition).to eq 0
        # rubocop:enable Lint/UselessComparison
      end

      it 'prefers the left side when the left side name sorts alphabetically before the right side name' do
        expect(described_class.new(:amount) <=> described_class.new(:quantity)).to eq(-1)
      end

      it 'prefers the right side when the right side name sorts alphabetically before the left side name' do
        expect(described_class.new(:quantity) <=> described_class.new(:amount)).to eq 1
      end
    end

    describe '#==' do
      it 'returns true when the attribute name is equal' do
        # rubocop:disable Lint/UselessComparison
        expect(described_class.new(:amount) == described_class.new(:amount)).to eq true
        # rubocop:enable Lint/UselessComparison
      end

      it 'returns false when another object is compared' do
        expect(described_class.new(:amount) == Struct.new(:name).new(:amount)).to eq false
      end

      it 'returns false when options differ' do
        expect(described_class.new(:amount) == described_class.new(:amount, type: String)).to eq false
      end
    end

    describe '#[]' do
      it 'reads an attribute option' do
        expect(attribute_definition[:default]).to eq 'default'
      end
    end

    describe '#initialize' do
      it 'raises an ArgumentError when no arguments' do
        expect { described_class.new }.to raise_error ArgumentError
      end

      it 'assigns the first argument to name' do
        expect(described_class.new(:amount).name).to eq :amount
      end

      it 'converts a String attribute name to a Symbol' do
        expect(described_class.new('amount').name).to eq :amount
      end

      it 'raises a TypeError when the attribute name does not respond to #to_sym' do
        expect { described_class.new(Object.new) }.to raise_error(TypeError, "can't convert Object into Symbol")
      end
    end

    describe '#inspect' do
      it 'generates attribute definition code for an attribute without options' do
        expect(described_class.new(:first_name).inspect).to eq %(attribute :first_name)
      end

      it 'generates attribute definition code for an attribute with a single option' do
        expect(described_class.new(:first_name, type: String).inspect).to eq %(attribute :first_name, :type => String)
      end

      it 'generates attribute definition code for an attribute with a single option, inspecting the option value' do
        expect(described_class.new(:first_name, default: 'John').inspect).to eq %(attribute :first_name, :default => "John")
      end

      it 'generates attribute definition code for an attribute with multiple options sorted alphabetically' do
        expected = %(attribute :first_name, :default => "John", :type => String)
        expect(described_class.new(:first_name, default: 'John', type: String).inspect).to eq expected
        expect(described_class.new(:first_name, type: String, default: 'John').inspect).to eq expected
      end

      it 'generate attribute definition code for an attribute with a string option key' do
        expect(described_class.new(:first_name, 'foo' => 'bar').inspect).to eq %(attribute :first_name, "foo" => "bar")
      end
    end

    describe '#name' do
      it { is_expected.to respond_to(:name) }
    end

    describe '#to_s' do
      it 'renders the name as a String' do
        expect(attribute_definition.to_s).to eq 'amount'
      end
    end

    describe '#to_sym' do
      it 'renders the name as a Symbol' do
        expect(attribute_definition.to_sym).to eq :amount
      end
    end
  end
end
