describe Neo4j::ActiveRel::Callbacks do
  after(:all) do
    [:CallbackBar, :CallbackFoo].each do |s|
      Object.send(:remove_const, s)
    end
  end
  let(:session) { double('Session') }
  let(:node1) { double('Node1') }
  let(:node2) { double('Node2') }

  class CallbackFoo
    def initialize(_args = nil); end

    def save(*)
      true
    end
  end

  class CallbackBar < CallbackFoo
    include Neo4j::ActiveRel::Callbacks
  end

  describe 'save' do
    let(:rel) { CallbackBar.new }

    before do
      @session = double('Mock Session')
      allow(Neo4j::Session).to receive(:current).and_return(@session)
      allow(CallbackBar).to receive(:neo4j_session).and_return(session)

      allow_any_instance_of(CallbackBar).to receive(:_persisted_obj).and_return(nil)
      allow_any_instance_of(CallbackBar).to receive_message_chain('errors.full_messages').and_return([])
    end

    it 'raises an error if unpersisted and outbound is not valid' do
      allow_any_instance_of(CallbackBar).to receive_message_chain('to_node.neo_id')
      allow_any_instance_of(CallbackBar).to receive_message_chain('from_node').and_return(nil)
      expect { rel.save }.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end

    it 'raises an error if unpersisted and inbound is not valid' do
      allow_any_instance_of(CallbackBar).to receive_message_chain('from_node.neo_id')
      allow_any_instance_of(CallbackBar).to receive_message_chain('to_node').and_return(nil)
      expect { rel.save }.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end

    it 'does not raise an error if inbound and outbound are valid' do
      allow_any_instance_of(CallbackBar).to receive_message_chain('from_node.neo_id')
      allow_any_instance_of(CallbackBar).to receive_message_chain('to_node.neo_id')
      expect { rel.save }.not_to raise_error
    end
  end
end
