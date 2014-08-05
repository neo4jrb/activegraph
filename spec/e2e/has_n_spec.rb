require 'spec_helper'

describe 'has_n' do

  let(:clazz_b) do
    UniqueClass.create do
      include Neo4j::ActiveNode
    end
  end

  let(:clazz_a) do
    #knows_type = clazz_b
    UniqueClass.create do
      include Neo4j::ActiveNode
      property :name

      has_many :both, :friends, model_class: false
      has_many :out, :knows, model_class: self
      has_many :in, :knows_me, origin: :knows, model_class: self
    end
  end

  let(:node) { clazz_a.create }
  let(:friend1) { clazz_a.create }
  let(:friend2) { clazz_a.create }

  describe 'rel_type' do
    it 'creates the correct type' do
      node.friends << friend1
      r = node.rel
      expect(r.rel_type).to eq(:'#friends')
    end

    it 'creates the correct type' do
      node.knows << friend1
      r = node.rel
      expect(r.rel_type).to eq(:'#knows')
    end

    it 'creates correct incoming relationship' do
      node.knows_me << friend1
      expect(friend1.rel(dir: :outgoing).rel_type).to eq(:'#knows')
      expect(node.rel(dir: :incoming).rel_type).to eq(:'#knows')
    end
  end

  it 'access nodes via declared has_n method' do
    expect(node.friends.to_a).to eq([])
    expect(node.friends.any?()).to be false

    node.friends << friend1
    expect(node.friends.to_a).to eq([friend1])
  end

  it 'access relationships via declared has_n method' do
    node.friends_rels.to_a.should eq([])
    node.friends << friend1
    rels = node.friends_rels
    rels.count.should == 1
    rel = rels.first
    rel.start_node.should == node
    rel.end_node.should == friend1
  end

  describe 'me.friends << friend_1 << friend' do
    it 'creates several relationships' do
      node.friends << friend1 << friend2
      node.friends.to_a.should =~ [friend1, friend2]
    end
  end

  describe 'me.friends = <array>' do
    it 'creates several relationships' do
      node.friends = [friend1, friend2]
      node.friends.to_a.should =~ [friend1, friend2]
    end

    context 'node with two friends' do
      before(:each) do
        node.friends = [friend1, friend2]
      end

      it 'is not empty' do
        expect(node.friends.any?()).to be true
      end

      it 'removes relationships when given a different list' do
        friend3 = clazz_a.create
        node.friends = [friend3]
        node.friends.to_a.should =~ [friend3]
      end

      it 'removes relationships when given a partial list' do
        node.friends = [friend1]
        node.friends.to_a.should =~ [friend1]
      end

      it 'removes all relationships when given an empty list' do
        node.friends = []
        node.friends.to_a.should =~ []
      end

      it 'can be accessed via [] operator' do
        expect([friend1, friend2]).to include(node.friends[0])
      end

      it 'has a to_s method' do
        expect(node.friends.to_s).to be_a(String)
      end

      it 'has a is_a method' do
        expect(node.friends.is_a?(Neo4j::ActiveNode::Query::QueryProxy)).to be true
        expect(node.friends.is_a?(Array)).to be false
        expect(node.friends.is_a?(String)).to be false
      end
    end
  end

  describe 'me.friends#create(other, since: 1994)' do
    describe "creating relationships to existing nodes" do
      it 'creates a new relationship when given existing nodes and given properties' do
        node.friends.create(friend1, since: 1994)

        r = node.rel(dir: :outgoing, type: '#friends')

        r[:since].should eq(1994)
      end

      it 'creates new relationships when given an array of nodes and given properties' do
        node.friends.create([friend1, friend2], since: 1995)

        rs = node.rels(dir: :outgoing, type: '#friends')

        rs.map(&:end_node).should =~ [friend1, friend2]
        rs.each do |r|
          r[:since].should eq(1995)
        end
      end
    end

    describe "creating relationships and nodes at the same time" do
      it 'creates a new relationship when given unpersisted node and given properties' do
        node.friends.create(clazz_a.new(name: 'Brad'), {since: 1996})

        r = node.rel(dir: :outgoing, type: '#friends')

        r[:since].should eq(1996)
        r.end_node.name.should == 'Brad'
      end

      it 'creates a new relationship when given an array of unpersisted nodes and given properties' do
        node.friends.create([clazz_a.new(name: 'James'), clazz_a.new(name: 'Cat')], {since: 1997})

        rs = node.rels(dir: :outgoing, type: '#friends')

        rs.map(&:end_node).map(&:name).should =~ ['James', 'Cat']
        rs.each do |r|
          r[:since].should eq(1997)
        end
      end
    end
  end
end
