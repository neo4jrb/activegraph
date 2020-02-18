describe 'works well together with ActiveGraph::Core' do
  before do
    clear_model_memory_caches

    stub_active_node_class('Clazz') do
      has_many :out, :stuff, type: :stuff, model_class: false
    end
  end

  it 'can add ActiveGraph::Core::Node to declared relationships' do
    obj = Clazz.create
    wrapped_node = Clazz.create
    node = wrapped_node._persisted_obj
    obj.stuff << node
    result = obj.query_as(:n).match('(n)-[:stuff]->(m)').pluck(:m)
    expect(result).to eq([wrapped_node])

    result = obj.stuff.to_a
    expect(result).to eq([wrapped_node])
  end

  # I don't think that this should work this way
  # Associations should always return the wrapped objects
  # Maybe we could support that via a method call, but it's easy enough to
  # map(&:_persisted_obj)
  #
  # it 'can retrieve ActiveGraph::Core::Node from declared relationships' do
  #   obj = Clazz.create
  #   node = Clazz.create._persisted_obj
  #   obj.stuff << node
  #   expect(obj.stuff.to_a).to eq([node])
  # end
end
