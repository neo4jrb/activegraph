require 'spec_helper'

describe Neo4j::ActiveNode::Persistence do
  let(:clazz) do
    Class.new do
      include ActiveAttr::MassAssignment
      include ActiveAttr::TypecastedAttributes
      include Neo4j::ActiveNode::Persistence

      attribute :name
      attribute :age, type: Integer

      def set_attributes(attrs)
        @attributes = attributes.merge(attrs.stringify_keys)
      end

      def get_attribute(name)
        send(:attribute, name)
      end
    end
  end

  describe 'persistable_attributes' do
    it 'returns type casted attributes and undeclared attributes' do
      o = clazz.new
      o.set_attributes('age' => '18')
      expect(o.get_attribute('age')).to eq(18)
      o.set_attributes('unknown' => 'yes')
      o.props.should == {:age => 18, :unknown => 'yes'}
    end

  end

end