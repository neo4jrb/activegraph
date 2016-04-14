describe Neo4j::ActiveRel::RelatedNode do
  class RelatedNode < Neo4j::ActiveRel::RelatedNode; end

  before { allow_any_instance_of(RelatedNode).to receive(:call) }

  let(:node1) { double('a wrapped node') }
  let(:rel)   { double('ActiveRel object') }

  describe 'initialize' do
    it 'can be called without params' do
      expect { RelatedNode.new }.not_to raise_error
    end
  end

  context 'initialized with a node id' do
    let(:r) { RelatedNode.new(1) }

    it 'sets @node' do
      expect(r.instance_variable_get(:@node)).to eq 1
    end

    describe 'loaded' do
      it 'loads the node from the server if not loaded' do
        expect(Neo4j::Node).to receive(:load).with(1).and_return(true)
        r.loaded
      end

      it 'changes the value of @node' do
        allow(Neo4j::Node).to receive(:load).and_return(node1)
        r.loaded
        expect(r.instance_variable_get(:@node)).to eq node1
      end

      context 'with @node unset' do
        let(:r) { RelatedNode.new(nil) }

        it 'raises' do
          expect { r.loaded }.to raise_error Neo4j::ActiveRel::RelatedNode::UnsetRelatedNodeError
        end
      end
    end

    describe 'loaded?' do
      it 'returns false' do
        expect(r.loaded?).to be_falsey
      end
    end

    describe '==' do
      it 'loads the node and compares' do
        expect(Neo4j::Node).to receive(:load).and_return(node1)
        expect(r == node1).to be_truthy
        expect(r.instance_variable_get(:@node)).to eq node1
      end
    end
  end

  context 'wrapped nodes' do
    before do
      allow(node1).to receive(:neo_id).and_return(1)
      allow(node1).to receive(:foo_prop).and_return(true)
    end
    let(:r) { RelatedNode.new(node1) }

    it 'accepts a wrapped node during initialize' do
      expect(r.instance_variable_get(:@node)).to eq node1
    end

    describe 'when loaded' do
      it 'does not call the server if the node is already loaded' do
        expect(Neo4j::Node).to_not receive(:load)
        r.loaded
      end

      it 'still has @node set to the wrapped node' do
        r.loaded
        expect(r.instance_variable_get(:@node)).to eq node1
      end
    end

    describe 'related nodes' do
      it 'respond to all methods not defined' do
        expect(node1).to receive(:name)
        r.name
      end

      it 'respond to :class' do
        expect(node1).to receive(:class)
        r.class
      end
    end

    describe 'loaded?' do
      it 'returns true' do
        expect(r.loaded?).to be_truthy
      end
    end

    describe '==' do
      it 'correctly compares nodes' do
        expect(r == node1).to be_truthy
      end
    end

    describe 'respond_to?' do
      it 'works correctly' do
        expect(r.respond_to?(:foo_prop)).to be_truthy
      end
    end
  end

  context 'when invalid' do
    it 'does not accept an invalid initialization param' do
      expect do
        RelatedNode.new(foo: 'bar')
      end.to raise_error(Neo4j::InvalidParameterError)
    end
  end
end
