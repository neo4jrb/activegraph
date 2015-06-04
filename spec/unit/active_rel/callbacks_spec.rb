require 'spec_helper'

describe Neo4j::ActiveRel::Callbacks do
  let(:session) { double('Session') }
  let(:node1) { double('Node1') }
  let(:node2) { double('Node2') }

  before do
    @session = double('Mock Session')
    Neo4j::Session.stub(:current).and_return(@session)
    clazz.stub(:neo4j_session).and_return(session)
  end

  class Foo
    def save(*)
      true
    end
  end

  let(:clazz) do
    class MyBar < Foo
      include Neo4j::ActiveRel::Callbacks
    end
  end

  describe 'save' do
    let(:rel) { clazz.new }

    before do
      clazz.any_instance.stub(:_persisted_obj).and_return(nil)
      clazz.any_instance.stub_chain('errors.full_messages').and_return([])
    end

    it 'raises an error if unpersisted and outbound is not valid' do
      clazz.any_instance.stub_chain('to_node.neo_id')
      clazz.any_instance.stub_chain('from_node').and_return(nil)
      expect { rel.save }.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end

    it 'raises an error if unpersisted and inbound is not valid' do
      clazz.any_instance.stub_chain('from_node.neo_id')
      clazz.any_instance.stub_chain('to_node').and_return(nil)
      expect { rel.save }.to raise_error(Neo4j::ActiveRel::Persistence::RelInvalidError)
    end

    it 'does not raise an error if inbound and outbound are valid' do
      clazz.any_instance.stub_chain('from_node.neo_id')
      clazz.any_instance.stub_chain('to_node.neo_id')
      expect { rel.save }.not_to raise_error
    end
  end
end
