describe Neo4j::ActiveNode::Query::QueryProxy do
  let(:qp) { Neo4j::ActiveNode::Query::QueryProxy.new(Object) }
  let(:session) { double('A session') }
  let(:query_result) { double('the result of calling :query') }
  let(:node) { double('A node object', foo: 'bar', neo_id: true) }
  let(:rel)  { double('A rel object') }
  let(:user_model) { double('A fake user model') }

  describe 'label generation' do
    before do
      stub_const('User::Foo', user_model)
      allow(user_model).to receive(:name).and_return('User::Foo')
    end

    it 'returns a correctly-formatted label' do
      expect(qp).to receive(:model).at_least(1).times.and_return(User::Foo)
      expect(qp.send(:_result_string)).to eq :result_userfoo
    end
  end

  describe 'each_with_rel' do
    it 'yields a node and rel object' do
      expect(qp).to receive(:pluck).and_return([node, rel])
      expect(qp.each_with_rel {}).to eq [node, rel]
    end
  end

  describe 'each_rel' do
    context 'without a block' do
      it 'calls to_enum, sends :each with node false, rel true' do
        expect(qp).to receive(:to_enum).with(:each, false, true)
        qp.each_rel
      end
    end

    context 'with a block' do
      it 'sends the block to :each with node false, rel true' do
        expect(qp).not_to receive(:to_enum)
        expect(qp).to receive(:each).with(false, true)
        qp.each_rel {}
      end

      it 'calls pluck and executes the block' do
        expect(qp).to receive(:pluck).and_return([rel])
        expect(rel).to receive(:name)
        qp.each_rel(&:name)
      end
    end
  end

  describe 'each_with_rel' do
    context 'without a block' do
      it 'calls to_enum, sends :each with node true, rel true' do
        expect(qp).to receive(:to_enum).with(:each, true, true)
        qp.each_with_rel
      end
    end

    context 'with a block' do
      it 'sends the block to :each with node true, rel true' do
        expect(qp).not_to receive(:to_enum)
        expect(qp).to receive(:each).with(true, true)
        qp.each_with_rel {}
      end

      it 'calls pluck and executes the block' do
        expect(qp).to receive(:pluck).and_return([node, rel])
        expect(node).to receive(:name)
        expect(rel).to receive(:name)
        qp.each_with_rel { |n, r| n.name && r.name }
      end
    end
  end

  describe 'to_cypher' do
    it 'calls query.to_cypher' do
      expect(qp).to receive(:query).and_return(query_result)
      expect(query_result).to receive(:to_cypher).and_return(String)
      qp.to_cypher
    end
  end

  describe '_association_chain_var' do
    context 'when missing start_object and query_proxy' do
      it 'raises a crazy error' do
        expect { qp.send(:_association_chain_var) }.to raise_error 'Crazy error'
      end

      it 'needs a better error than "crazy error"'
    end
  end

  describe '_association_query_start' do
    context 'when missing start_object and query_proxy' do
      it 'raises a crazy error' do
        expect { qp.send(:_association_query_start, nil) }.to raise_error 'Crazy error'
      end

      it 'needs a better error than "crazy error"'
    end
  end
end
