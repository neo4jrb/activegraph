require 'spec_helper'

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
    @n.nodes(dir: :outgoing).to_a.should =~ [@a]
  end

  it 'delegates #node' do
    @n.node(dir: :outgoing).should eq(@a)
  end

  it 'delegates #rels' do
    rels = @n.rels(dir: :outgoing)
    rels.count.should eq(1)
    rels.first.end_node.should eq(@a)
    rels.first.start_node.should eq(@n)
  end

  it 'delegates #rel' do
    rel = @n.rel(dir: :outgoing)
    rel.end_node.should eq(@a)
    rel.start_node.should eq(@n)
  end

  it 'delegates #rel?' do
    @n.rel?(dir: :outgoing).should be true
    @n.rel?(dir: :outgoing, type: :knows).should be false
  end

  it 'delegates #rel?' do
    @n.rel?(dir: :outgoing).should be true
    @n.rel?(dir: :outgoing, type: :knows).should be false
  end

end
