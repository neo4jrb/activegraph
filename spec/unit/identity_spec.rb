require 'spec_helper'

describe Neo4j::Library::Identity do
  let(:clazz) do
    Class.new do
      include Neo4j::ActiveNode::Persistence
      include Neo4j::Library::Identity
      include Neo4j::ActiveNode::Property

      def id
        neo_id
      end
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
      node.stub(:_persisted_obj).and_return(nil)
    end

    it 'should not have an idea before being persisted' do
      node.id.should be_nil
    end

    context 'a persisted record' do
      before(:each) do
        created_node.stub(:_persisted_obj).and_return(double(neo_id: 4387, del: true))
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
