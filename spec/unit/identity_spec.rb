require 'spec_helper'

describe Neo4j::ActiveNode::Persistence do
  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode::Persistence
      include Neo4j::ActiveNode::Identity
      include Neo4j::ActiveNode::Property
    end
  end

  describe '#id' do
    let(:session) { double("Session")}
    before do
      @session = double("Mock Session")
      Neo4j::Session.stub(:current).and_return(session)

    end

    let(:node) { clazz.new }
    let(:created_node) { clazz.new }

    before(:each) do
      node.stub(:_persisted_node).and_return(nil)
    end

    it 'should not have an idea before being persisted' do
      node.id.should be_nil
    end

    context 'a persisted record' do
      before(:each) do
        clazz.should_receive(:neo4j_session).and_return(session)
        clazz.should_receive(:mapped_label_names).and_return(:MyClass)

        created_node.should_receive(:props).and_return({})

        session.should_receive(:create_node).with({}, :MyClass).and_return(created_node)
        clazz.any_instance.should_receive(:init_on_load).with(created_node, {})

        created_node.should_receive(:_persisted_node).at_least(2).times.and_return double(neo_id: 4387, del: true)

        node.save
      end

      it 'should be the neo_id after it is saved' do
        created_node.id.should == 4387
      end

      it 'should be the neo_id after it is deleted' do
        created_node.destroy

        created_node.id.should == 4387
      end
    end
  end
end
