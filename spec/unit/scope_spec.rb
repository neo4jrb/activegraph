require 'spec_helper'

describe Neo4j::ActiveNode::Scope do

  let(:clazz) do
    UniqueClass.create do
      include Neo4j::ActiveNode
      scope :active, -> do
        where state: 'active'
      end
    end
  end

  it 'wraps the where method with a query_proxy' do
    query_proxy = double(:query_proxy)
    expect(query_proxy).to receive(:where).with({state: 'active'})
    clazz.stub(:query_proxy).and_return(query_proxy)
    clazz.active
  end
end
