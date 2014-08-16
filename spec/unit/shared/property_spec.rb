require 'spec_helper'

describe Neo4j::Shared::Property do 
  let(:clazz) { Class.new { include Neo4j::Shared::Property } }

  describe ':property class method' do
    it 'raises an error when passing illegal properties' do
      Neo4j::Shared::Property::ILLEGAL_PROPS.push 'foo'
      expect{clazz.property :foo}.to raise_error(Neo4j::Shared::Property::IllegalPropertyError)
    end
  end
end
