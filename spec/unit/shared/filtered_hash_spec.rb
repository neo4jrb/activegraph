module Neo4j::Shared
  describe FilteredHash do
    let(:base) { {first: :foo, second: :bar, third: :baz, fourth: :buzz} }
    let(:instructions) { :all }
    let(:filtered_props) { described_class.new(base, instructions) }

    describe '#initialize' do
      it 'takes a hash of properties and an instructions argument' do
        expect { filtered_props }.not_to raise_error
      end
    end

    describe 'accessors' do
      subject { described_class.new(base, instructions) }

      it { expect(subject.base).to eq base }
      it { expect(subject.instructions).to eq instructions }
    end

    describe 'instructions' do
      describe 'symbols' do
        it 'raise unless :all or :none' do
          expect { FilteredHash.new(base, :all) }.not_to raise_error
          expect { FilteredHash.new(base, :none) }.not_to raise_error
          expect { FilteredHash.new(base, :foo) }.to raise_error FilteredHash::InvalidHashFilterType
        end

        describe 'filtering' do
          context ':all' do
            let(:instructions) { :all }
            it 'returns [original_hash, empty_hash]' do
              expect(filtered_props.filtered_base).to eq([base, {}])
            end
          end

          context ':none' do
            let(:instructions) { :none }
            it 'returns [empty_hash, original_hash]' do
              expect(filtered_props.filtered_base).to eq([{}, base])
            end
          end
        end
      end

      describe 'hash' do
        it 'raises unless first key is :on' do
          expect { FilteredHash.new(base, on: :foo) }.not_to raise_error
          expect { FilteredHash.new(base, foo: :foo) }.to raise_error FilteredHash::InvalidHashFilterType
        end

        describe 'filtering' do
          context 'on:' do
            let(:instructions) { {on: [:second, :fourth]} }
            it 'returns [hash with keys specified, hash with remaining key' do
              expect(filtered_props.filtered_base).to eq([{second: :bar, fourth: :buzz}, {first: :foo, third: :baz}])
            end
          end
        end
      end
    end
  end
end
