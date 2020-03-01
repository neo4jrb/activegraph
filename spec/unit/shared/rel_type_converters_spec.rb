describe 'rel type conversion' do
  let(:clazz) do
    Class.new do
      include ActiveGraph::Shared::RelTypeConverters
    end
  end

  describe 'ActiveGraph::Config[:transform_rel_type]' do
    context 'with upcase' do
      before(:each) do
        ActiveGraph::Shared::RelTypeConverters.instance_variable_set(:@decorated_rel_type, nil)
        ActiveGraph::Shared::RelTypeConverters.instance_variable_set(:@rel_transformer, nil)
      end

      after(:all) { ActiveGraph::Config[:transform_rel_type] = :downcase }

      it 'upcases' do
        ActiveGraph::Config[:transform_rel_type] = :upcase
        expect(clazz.new.decorated_rel_type('RelType')).to eq 'REL_TYPE'
      end

      it 'downcases' do
        ActiveGraph::Config[:transform_rel_type] = :downcase
        expect(clazz.new.decorated_rel_type('RelType')).to eq 'rel_type'
      end

      it 'uses legacy' do
        ActiveGraph::Config[:transform_rel_type] = :legacy
        expect(clazz.new.decorated_rel_type('RelType')).to eq '#rel_type'
      end

      it 'uses none' do
        ActiveGraph::Config[:transform_rel_type] = :none
        expect(clazz.new.decorated_rel_type('RelType')).to eq 'RelType'
      end
    end
  end
end
