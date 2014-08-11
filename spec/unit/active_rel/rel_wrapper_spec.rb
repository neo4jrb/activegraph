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

  it 'looks for a _classname key' do
    expect(r.props).to receive(:has_key?).with(:_classname)
    r.wrapper
  end

  it 'returns self when unable to find a valid _classname' do
    expect(r.wrapper).to eq(r)
  end

  it 'calls init_on_load when finding a valid _classname' do
    r.stub(:props).and_return(name: 'superman', _classname: 'RelClass')
    expect(r).to receive(:_start_node_id)
    expect(r).to receive(:_end_node_id)
    expect(r).to receive(:rel_type).and_return('myrel')
    expect(r.wrapper).to be_a(RelClass)
  end

  it 'returns self when classname is invalid' do
    r.stub(:props).and_return(_classname: 'FakeClass')
    expect(r.wrapper).to eq r
  end
end