describe 'Neo4j::ActiveNode#rels' do
  before(:all) do
    clazz = UniqueClass.create do
      include Neo4j::ActiveNode
    end

    @n = clazz.create
    @a = clazz.create
    @b = clazz.create
    @n.create_rel(:friends, @a._persisted_obj)
    @a.create_rel(:knows, @b._persisted_obj)
  end

  it 'delegates #nodes' do
    expect(@n.nodes(dir: :outgoing).to_a).to match_array([@a])
  end

  it 'delegates #node' do
    expect(@n.node(dir: :outgoing)).to eq(@a)
  end

  it 'delegates #rels' do
    rels = @n.rels(dir: :outgoing)
    expect(rels.count).to eq(1)
    expect(rels.first.end_node).to eq(@a)
    expect(rels.first.start_node).to eq(@n)
  end

  it 'delegates #rel' do
    rel = @n.rel(dir: :outgoing)
    expect(rel.end_node).to eq(@a)
    expect(rel.start_node).to eq(@n)
  end

  it 'delegates #rel?' do
    expect(@n.rel?(dir: :outgoing)).to be true
    expect(@n.rel?(dir: :outgoing, type: :knows)).to be false
  end

  it 'delegates #rel?' do
    expect(@n.rel?(dir: :outgoing)).to be true
    expect(@n.rel?(dir: :outgoing, type: :knows)).to be false
  end
end
