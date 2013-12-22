require 'spec_helper'

describe Neo4j::ActiveNode::Persistence do
  let(:clazz) do
    Class.new do
      include ActiveAttr::Attributes
      include ActiveAttr::MassAssignment
      include ActiveAttr::TypecastedAttributes
      include ActiveAttr::AttributeDefaults
      include Neo4j::ActiveNode::Persistence

      attribute :name
      attribute :age, type: Integer

      def write_attribute(key, value)
        super(key,value)

        #key_s = key.to_s
        #if !@_properties.has_key?(key_s) || @_properties[key_s] != value
        #  attribute_will_change!(key_s)
        #  @_properties[key_s] = value.nil? ? attribute_defaults[key_s] : value
        #end
        #value
      end

      alias_method :[]=, :write_attribute

      def set_attributes(attrs)
        @attributes = attributes.merge(attrs.stringify_keys)
      end

      def get_attribute(name)
        send(:attribute, name)
      end
    end
  end

  describe 'props' do
    it 'works' do
      o = clazz.new
      o[:age] = '42'
      o[:age] = '41'
      #o[:name] = 'value'
    end

    it 'returns type casted attributes and undeclared attributes' do
      pending
      o = clazz.new
      o.set_attributes('age' => '18')
      expect(o.get_attribute('age')).to eq(18)
      o.set_attributes('unknown' => 'yes')
      o.props.should == {:age => 18, :unknown => 'yes'}
      o.name = 'hej'
    end

  end

end