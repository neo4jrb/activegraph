require 'spec_helper'

describe Neo4j::Core::Query::Parameters do
  let(:parameters) { Neo4j::Core::Query::Parameters.new }

  it 'lets you add params' do
    expect(parameters.add_param(:foo, 1)).to eq(:foo)

    expect(parameters.to_hash).to eq(foo: 1)
  end

  it 'lets you add a second param' do
    expect(parameters.add_param(:foo, 1)).to eq(:foo)
    expect(parameters.add_param(:bar, 'baz')).to eq(:bar)

    expect(parameters.to_hash).to eq(foo: 1, bar: 'baz')
  end

  it 'does not let the same parameter be used twice' do
    expect(parameters.add_param(:foo, 1)).to eq(:foo)
    expect(parameters.add_param(:foo, 2)).to eq(:foo2)

    expect(parameters.to_hash).to eq(foo: 1, foo2: 2)
  end

  it 'allows you to add multiple params at the same time' do
    expect(parameters.add_params(foo: 1)).to eq([:foo])
    expect(parameters.add_params(foo: 2, bar: 'baz')).to eq([:foo2, :bar])

    expect(parameters.to_hash).to eq(foo: 1, foo2: 2, bar: 'baz')
  end
end
