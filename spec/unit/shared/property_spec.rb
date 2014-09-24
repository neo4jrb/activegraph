require 'spec_helper'

describe Neo4j::Shared::Property do 
  let(:clazz) { Class.new { include Neo4j::Shared::Property } }

  describe ':property class method' do
    it 'raises an error when passing illegal properties' do
      Neo4j::Shared::Property::ILLEGAL_PROPS.push 'foo'
      expect{clazz.property :foo}.to raise_error(Neo4j::Shared::Property::IllegalPropertyError)
    end
  end

  describe '.undef_property' do
    before(:each) do
      clazz.property :bar

      expect(clazz).to receive(:undef_constraint_or_index)
      clazz.undef_property :bar
    end
    it 'removes methods' do
      clazz.method_defined?(:bar).should be false
      clazz.method_defined?(:bar=).should be false
      clazz.method_defined?(:bar?).should be false
    end
  end
end
