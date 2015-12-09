describe 'rel type conversion' do
  let(:clazz) do
    Class.new do
      include Neo4j::Shared::RelTypeConverters
    end
  end

  describe 'Neo4j::Config[:transform_rel_type]' do
    context 'with upcase' do
      before(:each) do
        Neo4j::Shared::RelTypeConverters.instance_variable_set(:@decorated_rel_type, nil)
        Neo4j::Shared::RelTypeConverters.instance_variable_set(:@rel_transformer, nil)
      end

      after(:all) { Neo4j::Config[:transform_rel_type] = :downcase }

      it 'upcases' do
        Neo4j::Config[:transform_rel_type] = :upcase
        expect(clazz.new.decorated_rel_type('RelType')).to eq 'REL_TYPE'
      end

      it 'downcases' do
        Neo4j::Config[:transform_rel_type] = :downcase
        expect(clazz.new.decorated_rel_type('RelType')).to eq 'rel_type'
      end

      it 'uses legacy' do
        Neo4j::Config[:transform_rel_type] = :legacy
        expect(clazz.new.decorated_rel_type('RelType')).to eq '#rel_type'
      end

      it 'uses none' do
        Neo4j::Config[:transform_rel_type] = :none
        expect(clazz.new.decorated_rel_type('RelType')).to eq 'RelType'
      end
    end
  end
end
