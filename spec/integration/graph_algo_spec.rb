require File.join(File.dirname(__FILE__), '..', 'spec_helper')



describe Neo4j::Algo, :type => :transactional do
  before(:each) do
    @x = Neo4j::Node.new :name => 'x'
    @a = Neo4j::Node.new :name => 'a'
    @b = Neo4j::Node.new :name => 'b'
    @c = Neo4j::Node.new :name => 'c'
    @d = Neo4j::Node.new :name => 'd'
    @e = Neo4j::Node.new :name => 'e'
    @f = Neo4j::Node.new :name => 'f'
    @y = Neo4j::Node.new :name => 'y'
  end

  describe "#dijkstra" do
    before(:each) do
      Neo4j::Relationship.new(:friends, @x, @y)[:weight] = 40.2
      Neo4j::Relationship.new(:friends, @x, @b)[:weight] = 3.0
      Neo4j::Relationship.new(:friends, @b, @c)[:weight] = 7.2
      Neo4j::Relationship.new(:friends, @b, @y)[:weight] =  10.2
      Neo4j::Relationship.new(:friends, @c, @y)[:weight] = 1.2
    end
    
    it "cost_evaluator{|rel,*| rel[:weight]} returns the shortest path given the weight property of the relationships" do
      res = Neo4j::Algo.dijkstra(@x,@y).cost_evaluator{|rel,*| rel[:weight]}
      res.should include(@x,@b,@c,@y)
    end
  end


  describe "#all_simple_paths(a,b)" do
    context "one outgoing path :friends exist between x and y of length 2" do
      before(:each) do
        @x.outgoing(:friends) << @a
        @a.outgoing(:friends) << @y
      end

      it "#outgoing(:friends).first.nodes returns the nodes in the path" do
        Neo4j::Algo.all_simple_paths(@x,@y).outgoing(:friends).first.nodes.should include(@x,@a,@y)
      end
    end
  end

  describe "#shortest_path(a,b)" do
    context "two outgoing path :friends exist between x and y of length 2 and 3" do
      before(:each) do
        # length 2
        new_tx
        @x = Neo4j::Node.new :name => 'x'
        @a = Neo4j::Node.new :name => 'a'
        @y = Neo4j::Node.new :name => 'y'
        @x.outgoing(:knows) << @a
        @a.outgoing(:knows) << @y
        # length 3
        @x.outgoing(:friends) << @b
        @b.outgoing(:friends) << @c
        @c.outgoing(:friends) << @y
      end

      it "#outgoing(:friends).outgoing(:knows) returns the nodes in the shortest path" do
        res = Neo4j::Algo.shortest_path(@x,@y).outgoing(:friends).outgoing(:knows)
        res.length.should == 2
        res.should include(@x,@a,@y)
      end

      it "#outgoing(:friends).rels returns the relationship in the shortest path" do
        res = Neo4j::Algo.shortest_path(@x,@y).outgoing(:friends).rels.to_a
        nodes = res.collect{|rel| rel.end_node}
        nodes.should include(@b,@c,@y)
      end

      it "#expand(proc) - only traverse the nodes given with the proc and return the nodes of the shortest path " do
        res = Neo4j::Algo.shortest_path(@x,@y).expand{|node| node._rels(:outgoing, :friends)}
        res.length.should == 3
        res.should include(@x,@b,@c,@y)
      end

      it "returns (using no outgoing,incoming,expand method) the shortest path of any relationship" do
        Neo4j::Algo.shortest_path(@x,@y).should include(@x,@a,@y)
        Neo4j::Algo.shortest_path(@x,@y).length.should == 2
      end

    end
  end

  describe "#all_paths(a,b)" do
    context "one outgoing path :friends exist between x and y of length 2" do
      before(:each) do
        @x.outgoing(:friends) << @a
        @a.outgoing(:friends) << @y
      end

      it "#outgoing(:friends).first.nodes returns the nodes in the path" do
        Neo4j::Algo.all_paths(@x,@y).outgoing(:friends).first.nodes.should include(@x,@a,@y)
      end

      it "#outgoing(:friends).depth(1).first == nil" do
        Neo4j::Algo.all_paths(@x,@y).outgoing(:friends).depth(1).first.should be_nil
      end

      it "#outgoing(:wrong_rel).depth(1).first == nil" do
        Neo4j::Algo.all_paths(@x,@y).outgoing(:wrong_rel).first.should be_nil
      end

      it "#outgoing(:friends).first.length == 2" do
        Neo4j::Algo.all_paths(@x,@y).outgoing(:friends).first.length == 2
      end

      it "#first.lengh == 2 (find all path with any relationship)" do
        Neo4j::Algo.all_paths(@x,@y).first.length == 2
        Neo4j::Algo.all_paths(@x,@y).first.nodes.should include(@x,@a,@y)
      end
    end

    context "two outgoing paths :friends exist between x and y of length 2" do
      before(:each) do
        # path 1
        @x.outgoing(:friends) << @a
        @a.outgoing(:friends) << @y

        # path 2
        @x.outgoing(:friends) << @b
        @b.outgoing(:friends) << @y
        @paths = [*Neo4j::Algo.all_paths(@x,@y).outgoing(:friends)]
      end

      it "#outgoing(:friends) should contain two paths" do
        @paths.size.should == 2
      end

      it "#outgoing(:friends) both paths should contain the nodes" do
        @paths[0].nodes.should include(@x,@y)
        @paths[1].nodes.should include(@x,@y)
        fail "expected either path 0 or path 1 include a" unless @paths[0].nodes.include?(@a) || @paths[1].nodes.include?(@a)
        fail "expected either path 0 or path 1 include b" unless @paths[0].nodes.include?(@b) || @paths[1].nodes.include?(@b)
      end
    end

  end
end
