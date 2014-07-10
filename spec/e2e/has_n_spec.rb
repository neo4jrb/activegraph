require 'spec_helper'

describe 'has_n' do

  let(:node) { clazz_a.create }
  let(:friend1) { clazz_a.create }
  let(:friend2) { clazz_a.create }

  let(:clazz_b) do
    UniqueClass.create do
      include Neo4j::ActiveNode
    end
  end

  let(:clazz_a) do
    knows_type = clazz_b.to_s
    UniqueClass.create do
      include Neo4j::ActiveNode

      property :before_callback_tester
      property :after_callback_tester

      has_n :friends
      has_n(:knows).to(knows_type)
      has_n(:knows_callback_before, before: :before_callback).to(knows_type)
      has_n(:knows_callback_after, after: :after_callback).to(knows_type)
      has_n(:knows_me).from(:knows)

      def before_callback(from, to)
        return false if from.before_callback_tester == 2
      end

      def after_callback(from, to)
        return false if from.after_callback_tester == 'foo'
        from.after_callback_tester = 2
        from.save
      end

      def before_callback_false(from, to)
        return false
      end

      def after_callback_false(from, to)
        return false
      end
    end
  end

  describe 'rel_type' do
    it 'creates the correct type' do
      node.friends << friend1
      r = node.rel
      expect(r.rel_type).to eq(:friends)
    end

    it 'creates the correct type' do
      node.knows << friend1
      r = node.rel
      expect(r.rel_type).to eq(:"#{clazz_a.to_s}#knows")
    end

    it 'creates correct incoming relationship' do
      node.knows_me << friend1
      expect(friend1.rel(dir: :outgoing).rel_type).to eq(:knows)
      expect(node.rel(dir: :incoming).rel_type).to eq(:knows)
    end
  end

  it 'access nodes via declared has_n method' do
    expect(node.friends.to_a).to eq([])
    expect(node.friends.empty?()).to be true

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
        expect(node.friends.empty?()).to be false
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
        expect(node.friends.is_a?(Array)).to be true
        expect(node.friends.is_a?(String)).to be false
      end
    end
  end

  describe 'me.friends.create(other, since: 1994)' do
    it 'creates a new relationship with given properties' do
      r = node.friends.create(friend1, since: 1994)

      r[:since].should eq(1994)
      node.rel(dir: :outgoing, type: clazz_a.friends).should == r
    end
  end

  describe 'callbacks' do
    describe 'before' do
      context 'failing' do
        before(:each) { friend1.before_callback_tester = 2 and friend1.save }

        it 'prevents a relationship from being created if response is explicitly false' do
          friend1.knows_callback_before << friend2
          expect(friend1.knows_callback_before.count).to eq 0
        end

        it 'returns false when the callback explicitly returns false' do
          friend1.before_callback_tester = 2 and friend1.save
          expect(friend1.knows_callback_before << friend2).to be_falsey
        end
      end

      context 'passing' do
        before(:each) { friend1.before_callback_tester = 1 and friend1.save }
        
        it 'creates the relationship when callback response is not explicitly false' do  
          friend1.knows_callback_before << friend2
          expect(friend1.knows_callback_before.count).to eq 1
        end
      end
    end

    describe 'after' do
      it 'runs the after callback function' do
        friend1.after_callback_tester = 1 and friend1.save
        friend1.knows_callback_after << friend2
        expect(friend1.after_callback_tester).to eq 2
      end

      it 'returns false if the callback explicitly returns false' do
        friend1.after_callback_tester = 'foo' and friend1.save
        expect(friend1.knows_callback_after << friend2).to be_falsey
      end

      it 'returns truthy if the callback returns anything but false' do
        expect(friend1.knows_callback_after << friend2).to be_truthy
      end
    end
  end
end
