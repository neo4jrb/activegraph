require 'spec_helper'

describe Neo4j::ActiveNode do
  before(:each) do
    stub_active_node_class('Person')
  end

  describe '#persisted?' do
    it 'returns false for new objects' do
      o = Person.new
      o.persisted?.should eq(false)
    end

    it 'returns true for created objects' do
      o = Person.create
      o.persisted?.should eq(true)
    end

    it 'returns false for destroyed objects' do
      o = Person.create
      o.destroy
      o.persisted?.should eq(false)
    end
  end
end
