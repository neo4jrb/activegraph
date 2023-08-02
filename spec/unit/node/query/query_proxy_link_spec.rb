describe ActiveGraph::Node::Query::QueryProxy::Link do
  describe 'label generation' do
    let(:generator) { described_class.uniq_param_generator_lambda }
    let(:params) { {result_teacher2_name: 'blah'} }
    let(:cypher_str) { "WHERE (result_teacher2.name = $#{old_param_key})" }
    let(:id) { 'n' }
    let(:counter) { 1 }
    let!(:old_param_key) { params.keys.first }
    let(:new_param_key) { "#{id}_UNION#{counter}_#{old_param_key}".to_sym }
    let(:expected_params) { {new_param_key => params.values.first} }

    subject { generator.call(params, cypher_str, id, counter) }

    it 'replaces param name in param hash' do
      expect(subject).to eq(expected_params)
    end

    it 'replaces param name in cypher string' do
      expected_cypher_str = cypher_str.gsub(old_param_key.to_s, new_param_key.to_s).tap { subject }
      expect(cypher_str).to eq(expected_cypher_str)
    end

    context 'with conflicting name within backtick' do
      let(:cypher_str) { "WHERE (`result_teacher2.#{old_param_key}` = $#{old_param_key})" }

      it 'ignores backtick variable names' do
        expect(subject).to eq(expected_params)
        expect(cypher_str).to eq("WHERE (`result_teacher2.#{old_param_key}` = $#{new_param_key})")
      end
    end

    context 'with conflicting name within single quote string value' do
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = '$#{old_param_key}') AND (result_teacher2.name = $#{old_param_key})" }

      it 'ignores variable names in single quote' do
        expect(subject).to eq(expected_params)
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = '$#{old_param_key}') AND (result_teacher2.name = $#{new_param_key})")
      end
    end

    context 'with conflicting name within double quote string value' do
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = \"$#{old_param_key}\") AND (result_teacher2.name = $#{old_param_key})" }

      it 'ignores variable names in double quote' do
        expect(subject).to eq(expected_params)
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = \"$#{old_param_key}\") AND (result_teacher2.name = $#{new_param_key})")
      end
    end

    context 'with nested quotes and backticks' do
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = \" ' $#{old_param_key} '\", \" `` 'blah `foo $#{old_param_key} bar` ' \")" }

      it 'ignores variable names in double quote' do
        subject
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = \" ' $#{old_param_key} '\", \" `` 'blah `foo $#{old_param_key} bar` ' \")")
      end
    end

    context 'when variable name is just after quote' do
      let(:cypher_str) { "'a'$#{old_param_key}" }

      it 'changes variable name' do
        subject
        expect(cypher_str).to eq("'a'$#{new_param_key}")
      end
    end

    context 'with nested quotes and backticks' do
      let(:cypher_str) { "'a' ,$#{old_param_key} \"\"'a$#{old_param_key}a'\"$#{old_param_key}\" \"\",$#{old_param_key} ``" }

      it 'ignores variable names in quotes' do
        subject
        expect(cypher_str).to eq("'a' ,$#{new_param_key} \"\"'a$#{old_param_key}a'\"$#{old_param_key}\" \"\",$#{new_param_key} ``")
      end
    end

    context 'with sequence of quotes' do
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = 'a', $#{old_param_key}, 'b')" }

      it 'replaces param correctly' do
        expect(subject).to eq(expected_params)
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = 'a', $#{new_param_key}, 'b')")
      end
    end

    context 'with spaces around quotes' do
      let(:combinations) do
        "'$#{old_param_key}', '$#{old_param_key} ', ' $#{old_param_key}',\
          ' $#{old_param_key}  ', 'sa as $#{old_param_key} da d asd'"
      end
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = #{combinations} AND result_teacher2.a = $#{old_param_key})" }

      it 'ignores variable names in single quotes' do
        expect(subject).to eq(expected_params)
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = #{combinations} AND result_teacher2.a = $#{new_param_key})")
      end
    end

    context 'with multiple params' do
      let(:params) { super().merge(question_mark_param: ['blah']) }
      let(:cypher_str) { "WHERE (result_teacher2.some_attr = $#{params.keys.last} ) AND (result_teacher2.name = $#{old_param_key})" }

      it 'ignores variable names in single quote' do
        expected_key1 = "#{id}_UNION#{counter}_#{params.keys.last}"
        expected_key2 = "#{id}_UNION#{counter}_#{old_param_key}"
        expect(subject).to eq({expected_key1.to_sym => ['blah'], expected_key2.to_sym => 'blah'})
        expect(cypher_str).to eq("WHERE (result_teacher2.some_attr = $#{expected_key1} ) AND (result_teacher2.name = $#{expected_key2})")
      end
    end
  end
end
