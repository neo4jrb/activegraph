require 'spec_helper'

describe Neo4j::ActiveRel::Callbacks do
  let(:session) { double('Session') }
  let(:node1) { double('Node1') }
  let(:node2) { double('Node2') }

  class Foo
    def initialize(_args = nil); end

    def save(*)
      true
    end
  end

  class Bar < Foo
    include Neo4j::ActiveRel::Callbacks
  end

  describe 'save' do
    let(:rel) { Bar.new }

    before do
      @session = double('Mock Session')
      Neo4j::Session.stub(:current).and_return(@session)
      Bar.stub(:neo4j_session).and_return(session)

      Bar.any_instance.stub(:_persisted_obj).and_return(nil)
      Bar.any_instance.stub_chain('errors.full_messages').and_return([])
    end

    it 'raises an error if unpersisted and outbound is not valid' do
      Bar.any_instance.stub_chain('to_node.neo_id')
      Bar.any_instance.stub_chain('from_node').and_return(nil)
      expect { rel.save }.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end

    it 'raises an error if unpersisted and inbound is not valid' do
      Bar.any_instance.stub_chain('from_node.neo_id')
      Bar.any_instance.stub_chain('to_node').and_return(nil)
      expect { rel.save }.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end

    it 'does not raise an error if inbound and outbound are valid' do
      Bar.any_instance.stub_chain('from_node.neo_id')
      Bar.any_instance.stub_chain('to_node.neo_id')
      expect { rel.save }.not_to raise_error
    end
  end
end
