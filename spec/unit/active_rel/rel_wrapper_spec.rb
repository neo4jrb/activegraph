require 'spec_helper'

describe Neo4j::Relationship::Wrapper do
  class RelClass; end

  let(:clazz) do
    Class.new do
      include Neo4j::Relationship::Wrapper
    end
  end

  before do
    clazz.any_instance.stub(:props).and_return('name' => 'superman')
    RelClass.any_instance.stub(:init_on_load)
  end

  let(:r) { clazz.new }

  it 'converts symbolizes the keys of properties' do
    r.wrapper
    expect(r.props).to eq name: 'superman'
  end

  it 'returns self when unable to find a valid class' do
    expect(r.wrapper).to eq(r)
  end
end
