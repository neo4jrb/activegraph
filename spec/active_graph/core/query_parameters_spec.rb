describe ActiveGraph::Core::Query::Parameters do
  let(:parameters) { ActiveGraph::Core::Query::Parameters.new }

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
    expect(parameters.add_params(foo: 2, bar: 'baz')).to eq(%i[foo2 bar])

    expect(parameters.to_hash).to eq(foo: 1, foo2: 2, bar: 'baz')
  end

  context 'with a prefix' do
    let(:parameters) { ActiveGraph::Core::Query::Parameters.new({foo: 1}, 'b1_') }

    it 'prefixes the generated names and not the names the caller chose' do
      expect(parameters.add_param(:foo, 2)).to eq(:b1_foo)
      expect(parameters.add_params(foo: 3, bar: 'baz')).to eq(%i[b1_foo2 b1_bar])
      expect(parameters.add_named_param(:foo, 4)).to eq(:foo2)
      expect(parameters.add_named_params(foo: 5)).to eq([:foo3])

      expect(parameters.to_hash).to eq(foo: 1, b1_foo: 2, b1_foo2: 3, b1_bar: 'baz', foo2: 4, foo3: 5)
      expect(parameters.copy.prefix).to eq('b1_')
    end
  end

  describe '#add_final_params' do
    it 'keeps the names and rejects a name bound to another value' do
      parameters.add_param(:foo, 1)
      parameters.add_final_params(foo: 1, b1_foo: 2)
      expect(parameters.to_hash).to eq(foo: 1, b1_foo: 2)

      expect { parameters.add_final_params(foo: 3, b1_foo: 2) }
        .to raise_error(CypherDSL::ConflictingParametersException, /foo/)
      expect(parameters.to_hash).to eq(foo: 1, b1_foo: 2)
    end
  end
end
