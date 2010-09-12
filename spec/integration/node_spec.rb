require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Node, :type => :transactional do

  describe "#new" do
    it "created node should exist in db after transaction finish" do
      new_node = Neo4j::Node.new
      Neo4j::Transaction.finish
      Neo4j::Node.should exist(new_node)
    end

    it "created node should exist in db before transaction finish" do
      new_node = Neo4j::Node.new
      Neo4j::Node.should exist(new_node)
      Neo4j::Transaction.finish
    end
  end

  describe "#del" do
    it "deletes the node - does not exist after the transaction finish" do
      new_node = Neo4j::Node.new
      new_node.del
      Neo4j::Transaction.finish
      Neo4j::Node.should_not exist(new_node.id)
    end

    it "deletes the node - does not exist before the transaction finish" do
      new_node = Neo4j::Node.new
      id = new_node.id
      new_node.del
      Neo4j::Node.should_not exist(id)
    end

    it "modify an deleted node will raise en exception" do
      new_node = Neo4j::Node.new
      new_node.del
      expect { Neo4j::Transaction.run{ new_node[:foo] = 'bar'}}.to raise_error
    end

  end

  describe "#[] and #[]=" do
    it "set and get String properties" do
      new_node = Neo4j::Node.new
      new_node[:key] = 'myvalue'
      new_node[:key].should == 'myvalue'
    end

    it "set and get Fixnum properties" do
      new_node = Neo4j::Node.new
      new_node[:key] = 42
      new_node[:key].should == 42
    end


    it "set and get Float properties" do
      new_node = Neo4j::Node.new
      new_node[:key] = 3.1415
      new_node[:key].should == 3.1415
    end

    it "set and get Boolean properties" do
      new_node = Neo4j::Node.new
      new_node[:key] = true
      new_node[:key].should == true
      new_node[:key] = false
      new_node[:key].should == false
    end


    it "set and get properties with a String key" do
      new_node = Neo4j::Node.new
      new_node["a"] = 'foo'
      new_node["a"].should == 'foo'
    end

    it "deletes the property if value is nil" do
      new_node = Neo4j::Node.new
      new_node[:key] = 'myvalue'
      new_node.property?(:key).should be_true
      Neo4j::Transaction.finish
      Neo4j::Transaction.new
      new_node[:key] = nil
      new_node.property?(:key).should be_false
    end

  end

  describe "#update" do
    it "updates properties" do
      new_node = Neo4j::Node.new
      new_node.update :name => 'foo', :age => 123
      new_node[:name].should == 'foo'
      new_node[:age].should == 123
    end
  end



  describe "Relationships" do

    def create_nodes
      #
      #  a --friend--> b  --friend--> c
      #                |              ^
      #                |              |
      #                +--- work -----+
      #                |
      #                +--- work ---> d  --- work --> e
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new
      d = Neo4j::Node.new
      e = Neo4j::Node.new
      a.outgoing(:friends) << b
      b.outgoing(:friends) << c
      b.outgoing(:work) << c
      b.outgoing(:work) << d
      d.outgoing(:work) << e
      [a,b,c,d,e]
    end


    it "#rel? returns true if there are any relationship" do
      a = Neo4j::Node.new
      a.rel?.should be_false
      a.outgoing(:foo) << Neo4j::Node.new
      a.rel?.should be_true
      a.rel?(:bar).should be_false
      a.rel?(:foo).should be_true
      a.rel?(:foo, :incoming).should be_false
      a.rel?(:foo, :outgoing).should be_true
    end

    it "#outgoing(:friends) << other_node creates an outgoing relationship of type :friends" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      a.outgoing(:friends) << other_node

      # then
      a.outgoing(:friends).first.should == other_node
    end

    it "#incoming(:friends) << other_node should raise an exception" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      expect { a.incoming(:friends) << other_node }.to raise_error
    end

    it "#both(:friends) << other_node should raise an exception" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      expect { a.both(:friends) << other_node }.to raise_error
    end

    it "#both returns all outgoing nodes of any type" do
      a,b,c,d = create_nodes
      b.both.should include(a,c,d)
      [*b.both].size.should == 3
    end

    it "#incoming returns all incoming nodes of any type" do
      pending
      a,b,c,d = create_nodes
      #b.incoming.should include(...)
      #[*b.incoming].size.should == .
    end

    it "#outgoing returns all outgoing nodes of any type" do
      pending
      a,b,c,d = create_nodes
      #b.outgoing.should include()
      #[*b.outgoing].size.should == ..
    end

    it "#outgoing(type) should only return outgoing nodes of the given type of depth one" do
      a,b,c,d = create_nodes
      b.outgoing(:work).should include(c,d)
      [*b.outgoing(:work)].size.should == 2
    end

    it "#outgoing(type).depth(4) should only return outgoing nodes of the given type and depth" do
      a,b,c,d,e = create_nodes
      [*b.outgoing(:work).depth(4)].size.should == 3
      b.outgoing(:work).depth(4).should include(c,d,e)
    end

    it "#outgoing(type).depth(4).include_start_node should also include the start node" do
      a,b,c,d,e = create_nodes
      [*b.outgoing(:work).depth(4).include_start_node].size.should == 4
      b.outgoing(:work).depth(4).include_start_node.should include(b,c,d,e)
    end

    it "#outgoing(type).depth(:all) should traverse at any depth" do
      a,b,c,d,e = create_nodes
      [*b.outgoing(:work).depth(:all)].size.should == 3
      b.outgoing(:work).depth(:all).should include(c,d,e)
    end

    it "#incoming(type).depth(2) should only return outgoing nodes of the given type and depth" do
      a,b,c,d,e = create_nodes
      [*e.incoming(:work).depth(2)].size.should == 2
      e.incoming(:work).depth(2).should include(b,d)
    end


    it "#incoming(type) should only return incoming nodes of the given type of depth one" do
      a,b,c,d = create_nodes
      c.incoming(:work).should include(b)
      [*c.incoming(:work)].size.should == 1
    end

    it "#both(type) should return both incoming and outgoing nodes of the given type of depth one" do
      a,b,c,d = create_nodes
#      [a,b,c,d].each_with_index {|n,i| puts "#{i} : id #{n.id}"}
      b.both(:friends).should include(a,c)
      [*b.both(:friends)].size.should == 2
    end

    it "#outgoing and #incoming can be combined to traverse several relationship types" do
      a,b,c,d,e = create_nodes
      nodes = [*b.incoming(:friends).outgoing(:work)]
      nodes.should include(a,c,d)
      nodes.should_not include(b,e)
    end


    it "#prune takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
      a, b, c, d, e = create_nodes
      b.outgoing(:friends).depth(4).prune{|path| path.should be_kind_of(Java::org.neo4j.graphdb.Path); false}.each {}
    end

    it "#prune, if it returns true the traversal will be 'cut off' that path" do
      a, b, c, d, e = create_nodes


      [*b.outgoing(:work).depth(4).prune{|path| true}].size.should == 2
      b.outgoing(:work).depth(4).prune{|path| true}.should include(c,d)
    end

    it "#filter takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
      a, b, c, d, e = create_nodes
      b.outgoing(:friends).depth(4).filter{|path| path.should be_kind_of(Java::org.neo4j.graphdb.Path); false}.each {}
    end

    it "#filter takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
      a, b, c, d, e = create_nodes
      #[a,b,c,d,e].each_with_index {|n,i| puts "#{i} : id #{n.id}"}

      # only returns nodes with path length == 2
      nodes = [*b.outgoing(:work).depth(4).filter{|path| path.length == 2}]
      nodes.size.should == 1
      nodes.should include(e)
    end


    it "#rels should return both incoming and outgoing relationship of any type of depth one" do
      a,b,c,d,e = create_nodes
      [*b.rels].size.should == 4
      nodes = b.rels.collect{|r| r.end_node}
      nodes.should include(b,d)
      nodes.should_not include(a,c,e)
    end

    it "#rels(:friends) should return both incoming and outgoing relationships of given type of depth one" do
      # given
      a,b,c,d,e = create_nodes

      # when
      rels = [*b.rels(:friends)]

      # then
      rels.size.should == 2
      nodes = rels.collect{|r| r.end_node}
      nodes.should include(b,c)
      nodes.should_not include(a,d,e)
    end

    it "#rels(:friends).outgoing should return only outgoing relationships of given type of depth one" do
      # given
      a,b,c,d,e = create_nodes

      # when
      rels = [*b.rels(:friends).outgoing]

      # then
      rels.size.should == 1
      nodes = rels.collect{|r| r.end_node}
      nodes.should include(c)
      nodes.should_not include(a,b,d,e)
    end


    it "#rels(:friends).incoming should return only outgoing relationships of given type of depth one" do
      # given
      a,b,c,d,e = create_nodes

      # when
      rels = [*b.rels(:friends).incoming]

      # then
      rels.size.should == 1
      nodes = rels.collect{|r| r.start_node}
      nodes.should include(a)
      nodes.should_not include(b,c,d,e)
    end

    it "#rels(:friends,:work) should return both incoming and outgoing relationships of given types of depth one" do
      # given
      a,b,c,d,e = create_nodes

      # when
      rels = [*b.rels(:friends,:work)]

      # then
      rels.size.should == 4
      nodes = rels.collect{|r| r.end_node}
      nodes.should include(b,c,d)
      nodes.should_not include(a,e)
    end

    it "#rels(:friends,:work).outgoing/incoming should raise exception" do
      node = Neo4j::Node.new
      expect{ node.rels(:friends, :work).outgoing }.to raise_error
      expect{ node.rels(:friends, :work).incoming }.to raise_error
    end


  end


end