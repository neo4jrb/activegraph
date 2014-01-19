require 'spec_helper'

describe 'has_n' do

  let(:clazz) do
    UniqueClass.create do
      include Neo4j::ActiveNode
      has_n :friends
    end
  end

  it 'access nodes via declared has_n method' do
    a = clazz.create
    a.friends.to_a.should eq([])
    b = clazz.create
    a.friends << b
    a.friends.to_a.should eq([b])
  end

  it 'access relationships via declared has_n method' do
    a = clazz.create
    a.friends_rels.to_a.should eq([])
    b = clazz.create
    a.friends << b
    rels = a.friends_rels
    rels.count.should == 1
    rel = rels.first
    rel.start_node.should == a
    rel.end_node.should == b
  end

  describe 'me.friends << friend_1 << friend' do
    it 'creates several relationships' do
      a = clazz.create
      b = clazz.create
      c = clazz.create
      a.friends << b << c
      a.friends.to_a.should =~ [b,c]
    end
  end

  describe 'me.friends.create(other, since: 1994)' do
    it 'creates a new relationship with given properties' do
      a = clazz.create
      b = clazz.create
      r = a.friends.create(b, since: 1994)
      r[:since].should eq(1994)
      a.rel(dir: :outgoing, type: clazz.friends).should == r
    end
  end
end