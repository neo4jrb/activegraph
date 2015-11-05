require 'spec_helper'

module Neo4j::Shared::Property
  describe FilteredProperties do
    let(:properties) { {first: :foo, second: :bar, third: :baz, fourth: :buzz} }
    let(:instructions) { :all }
    let(:filtered_props) { described_class.new(properties, instructions) }

    describe '#initialize' do
      it 'takes a hash of properties and an instructions argument' do
        expect { filtered_props }.not_to raise_error
      end
    end

    describe 'accessors' do
      subject { described_class.new(properties, instructions) }

      it { expect(subject.properties).to eq properties }
      it { expect(subject.instructions).to eq instructions }
    end

    describe 'instructions' do
      describe 'symbols' do
        it 'raise unless :all or :none' do
          expect { FilteredProperties.new(properties, :all) }.not_to raise_error
          expect { FilteredProperties.new(properties, :none) }.not_to raise_error
          expect { FilteredProperties.new(properties, :foo) }.to raise_error FilteredProperties::InvalidPropertyFilterType
        end

        describe 'filtering' do
          context ':all' do
            let(:instructions) { :all }
            it 'returns [original_hash, empty_hash]' do
              expect(filtered_props.filtered_properties).to eq([properties, {}])
            end
          end

          context ':none' do
            let(:instructions) { :none }
            it 'returns [empty_hash, original_hash]' do
              expect(filtered_props.filtered_properties).to eq([{}, properties])
            end
          end
        end
      end

      describe 'hash' do
        it 'raises unless first key is :on or :except' do
          expect { FilteredProperties.new(properties, on: :foo) }.not_to raise_error
          expect { FilteredProperties.new(properties, except: :foo) }.not_to raise_error
          expect { FilteredProperties.new(properties, foo: :foo) }.to raise_error FilteredProperties::InvalidPropertyFilterType
        end

        describe 'filtering' do
          context 'on:' do
            let(:instructions) { {on: [:second, :fourth]} }
            it 'returns [hash with keys specified, hash with remaining key' do
              expect(filtered_props.filtered_properties).to eq([{second: :bar, fourth: :buzz}, {first: :foo, third: :baz}])
            end
          end

          context 'except:' do
            let(:instructions) { {except: [:second, :fourth]} }
            it 'returns [hash without keys specified, hash with keys specified' do
              expect(filtered_props.filtered_properties).to eq([{first: :foo, third: :baz}, {second: :bar, fourth: :buzz}])
            end
          end
        end
      end
    end
  end
end
