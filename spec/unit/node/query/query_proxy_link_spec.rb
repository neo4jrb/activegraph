describe ActiveGraph::Node::Query::QueryProxy::Link do
  describe 'label generation' do
    let(:generator) { described_class.uniq_param_generator_lambda }
    let(:params) { { result_teacher2_name: 'blah' } }
    let(:cypher_str) { "WHERE (result_teacher2.name = $#{old_param_key})" }
    let(:id) { 'n' }
    let(:counter) { 1 }
    let!(:old_param_key) { params.keys.first }

    subject { generator.call(params, cypher_str, id, counter) }

    it 'replaces param name in param hash' do
      expect(subject).to eq({ :"#{id}_UNION#{counter}_#{old_param_key}" => 'blah' })
    end

    it 'replaces param name in cypher string' do
      expected_cypher_str = cypher_str.gsub("#{old_param_key}", "#{id}_UNION#{counter}_#{old_param_key}").tap { subject }
      expect(cypher_str).to eq(expected_cypher_str)
    end

    context 'with conflicting name within backtick' do
      let(:cypher_str) { "WHERE (`result_teacher2.#{old_param_key}` = $#{old_param_key})" }

      it 'ignores backtick variable names' do
        expected_key = "#{id}_UNION#{counter}_#{old_param_key}"
        expect(subject).to eq({ expected_key.to_sym => 'blah' })
        expect(cypher_str).to eq("WHERE (`result_teacher2.#{old_param_key}` = $#{expected_key})")
      end
    end

    context 'with conflicting name within single quote string value' do
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = '$#{old_param_key}') AND (result_teacher2.name = $#{old_param_key})" }

      it 'ignores variable names in single quote' do
        expected_key = "#{id}_UNION#{counter}_#{old_param_key}"
        expect(subject).to eq({ expected_key.to_sym => 'blah' })
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = '$#{old_param_key}') AND (result_teacher2.name = $#{expected_key})")
      end
    end

    context 'with conflicting name within double quote string value' do
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = \"$#{old_param_key}\") AND (result_teacher2.name = $#{old_param_key})" }

      it 'ignores variable names in single quote' do
        expected_key = "#{id}_UNION#{counter}_#{old_param_key}"
        expect(subject).to eq({ expected_key.to_sym => 'blah' })
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = \"$#{old_param_key}\") AND (result_teacher2.name = $#{expected_key})")
      end
    end

    context 'with multiple params' do
      let(:params) { super().merge(question_mark_param: ['blah']) }
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = $#{params.keys.last} ) AND (result_teacher2.name = $#{old_param_key})" }

      it 'ignores variable names in single quote' do
        expected_key_1 = "#{id}_UNION#{counter}_#{params.keys.last}"
        expected_key_2 = "#{id}_UNION#{counter}_#{old_param_key}"
        expect(subject).to eq({ expected_key_1.to_sym => ['blah'], expected_key_2.to_sym => 'blah' })
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = $#{expected_key_1} ) AND (result_teacher2.name = $#{expected_key_2})")
      end
    end
  end
end
