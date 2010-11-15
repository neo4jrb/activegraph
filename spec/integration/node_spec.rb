require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Node, :type => :transactional do

  describe "#new" do
    it "created node should exist in db before transaction finish" do
      new_node = Neo4j::Node.new
      new_node.should exist
    end

    it "initialize it with the given hash of properties" do
      new_node = Neo4j::Node.new :name => 'my name', :age => 42
      new_node[:name].should == 'my name'
      new_node[:age].should == 42
    end

  end

  describe "#del" do
    it "deletes the node - does not exist after the transaction finish" do
      new_node = Neo4j::Node.new
      new_node.del
      finish_tx
      Neo4j::Node.should_not exist(new_node.id)
    end

    it "deletes the node - does exist before the transaction finish but not after" do
      new_node = Neo4j::Node.new
      new_node.del
      new_node.should exist
      finish_tx
      new_node.should_not exist
    end

    it "modify an deleted node will raise en exception" do
      new_node = Neo4j::Node.new
      new_node.del
      expect { new_node[:foo] = 'bar'}.to raise_error
      expect { finish_tx }.to raise_error
    end

    it "update and then delete the same node in one transaction is okey" do
      a = Neo4j::Node.new
      new_tx
      a2 = Neo4j::Node.load(a.neo_id)
      a2[:kalle] = 'kalle'
      a2.delete
      expect { finish_tx }.to_not raise_error
    end

    it "deletes" do
      a = Neo4j::Node.new
      new_tx
      id = a.neo_id
      x = Neo4j::Node.load(id)
      x.del
    end

    it "will delete all relationship as well" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new
      a.outgoing(:friends) << b
      b.outgoing(:work) << c << a
      a.rels.size.should == 2
      c.rels.size.should == 1

      # when
      b.del

      # then
      a.rels.size.should == 0
      c.rels.size.should == 0
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
      new_tx
      new_node[:key] = nil
      new_node.property?(:key).should be_false
    end

    it "allow to store array of Fixnum values" do
      new_node = Neo4j::Node.new
      new_node[:key] = [1,2,3]
      new_node[:key][0].should == 1
      new_node[:key][1].should == 2
      new_node[:key][2].should == 3      
    end

    it "allow to store array of String values" do
      new_node = Neo4j::Node.new
      new_node[:key] = %w[a b c]
      new_node[:key][0].should == 'a'
      new_node[:key][1].should == 'b'
      new_node[:key][2].should == 'c'
    end

    it "allow to store array of Float values" do
      new_node = Neo4j::Node.new
      new_node[:key] = [1.2, 3.14, 998.32]
      new_node[:key][0].should == 1.2
      new_node[:key][1].should == 3.14
      new_node[:key][2].should == 998.32
    end

    it "allow to store array of boolean values" do
      new_node = Neo4j::Node.new
      new_node[:key] = [true, false, true]
      new_node[:key][0].should == true
      new_node[:key][1].should == false
      new_node[:key][2].should == true
    end

    it "allow to store empty array " do
      new_node = Neo4j::Node.new
      new_node[:key] = []
      size = new_node[:key].size
      0.should == size
    end

    it "is not possible to delete or add an item in the array" do
      new_node = Neo4j::Node.new
      new_node[:key] = %w[a b c]
      new_tx
      new_node[:key].delete('b')
      new_tx
      new_node[:key][0].should == 'a'
      new_node[:key][1].should == 'b'
      new_node[:key][2].should == 'c'
    end
    
    it "does not allow to store an array of different value types" do
      new_node = Neo4j::Node.new
      expect { new_node[:key] = [true, "hej", 42] }.to raise_error
    end

    it "is possible to change type of array if all items are of same type" do
      new_node = Neo4j::Node.new
      new_node[:key] = [1, 2, 3]
      expect { new_node[:key] = %w[a, b, c] }.to_not raise_error
    end
    
  end

  describe "#update" do
    it "updates properties" do
      new_node = Neo4j::Node.new
      new_node.update :name => 'foo', :age => 123
      new_node[:name].should == 'foo'
      new_node[:age].should == 123
    end

    it "updated properties will exist for a loaded node before the transaction commits" do
      new_node = Neo4j::Node.new
      new_node[:name] = 'abc'
      new_tx
      new_node[:name] = '123'
      node = Neo4j::Node.load(new_node.neo_id)
      node[:name].should == '123'
    end
  end



  describe "Relationships" do

    def create_nodes
      #
      #                f
      #                ^
      #              friends
      #                |
      #  a --friends-> b  --friends--> c
      #                |              ^
      #                |              |
      #                +--- work  -----+
      #                |
      #                +--- work  ---> d  --- work --> e
      a = Neo4j::Node.new :name => 'a'
      b = Neo4j::Node.new :name => 'b'
      c = Neo4j::Node.new :name => 'c'
      d = Neo4j::Node.new :name => 'd'
      e = Neo4j::Node.new :name => 'e'
      f = Neo4j::Node.new :name => 'f'
      a.outgoing(:friends) << b
      b.outgoing(:friends) << c
      b.outgoing(:work) << c
      b.outgoing(:work) << d
      d.outgoing(:work) << e
      b.outgoing(:friends) << f
      [a,b,c,d,e,f]
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

    it "#outgoing(:friends) << b << c creates an outgoing relationship of type :friends" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new

      # when
      a.outgoing(:friends) << b << c

      # then
      a.outgoing(:friends).should include(b,c)
    end

    it "#incoming(:friends) << other_node should add an incoming relationship" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      a.incoming(:friends) << other_node

      # then
      a.incoming(:friends).first.should == other_node
    end

    it "#both(:friends) << other_node should raise an exception" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      expect { a.both(:friends) << other_node }.to raise_error
    end

    it "#both returns all outgoing nodes of any type" do
      a,b,c,d,e,f = create_nodes
      b.both.should include(a,c,d,f)
      [*b.both].size.should == 4
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

    it "#outgoing(type1).outgoing(type2) should return outgoing nodes of the given types" do
      a,b,c,d,e,f = create_nodes
      nodes = b.outgoing(:work).outgoing(:friends)
      nodes.should include(c,d,f)
      nodes.size.should == 3
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
      a,b,c,d,e,f = create_nodes
#      [a,b,c,d].each_with_index {|n,i| puts "#{i} : id #{n.id}"}
      b.both(:friends).should include(a,c,f)
      [*b.both(:friends)].size.should == 3
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

    it "#filter accept several filters which all must return true in order to include the node in the traversal result" do
      a, b, c, d, e = create_nodes
      nodes = [*b.outgoing(:work).depth(4).filter{|path| %w[c d].include?(path.end_node[:name]) }.
              filter{|path| %w[d e].include?(path.end_node[:name]) }]
      nodes.should include(d)
      nodes.should_not include(e)
      nodes.size.should == 1
    end

    it "#rels should return both incoming and outgoing relationship of any type of depth one" do
      a,b,c,d,e,f = create_nodes
      b.rels.size.should == 5
      nodes = b.rels.collect{|r| r.other_node(b)}
      nodes.should include(a,c,d,f)
      nodes.should_not include(e)
    end

    it "#rels(:friends) should return both incoming and outgoing relationships of given type of depth one" do
      # given
      a,b,c,d,e,f = create_nodes

      # when
      rels = [*b.rels(:friends)]

      # then
      rels.size.should == 3
      nodes = rels.collect{|r| r.end_node}
      nodes.should include(b,c,f)
      nodes.should_not include(a,d,e)
    end

    it "#rels(:friends).outgoing should return only outgoing relationships of given type of depth one" do
      # given
      a,b,c,d,e,f = create_nodes

      # when
      rels = [*b.rels(:friends).outgoing]

      # then
      rels.size.should == 2
      nodes = rels.collect{|r| r.end_node}
      nodes.should include(c,f)
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
      a,b,c,d,e,f = create_nodes

      # when
      rels = [*b.rels(:friends,:work)]

      # then
      rels.size.should == 5
      nodes = rels.collect{|r| r.other_node(b)}
      nodes.should include(a,c,d,f)
      nodes.should_not include(b,e)
    end

    it "#rels(:friends,:work).outgoing/incoming should raise exception" do
      node = Neo4j::Node.new
      expect{ node.rels(:friends, :work).outgoing }.to raise_error
      expect{ node.rels(:friends, :work).incoming }.to raise_error
    end

    it "#rel returns a single relationship if there is only one relationship" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      rel = Neo4j::Relationship.new(:friend, a, b)
      a.rel(:outgoing, :friend).should == rel
    end

    it "#rel returns nil if there is no relationship" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      a.rel(:outgoing, :friend).should be_nil
    end

    it "#rel should raise an exception if there are more then one relationship" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new
      Neo4j::Relationship.new(:friend, a, b)
      Neo4j::Relationship.new(:friend, a, c)
      expect { a.rel(:outgoing, :friend)}.to raise_error
    end

    it "#rels returns a RelationshipTraverser which can filter which relationship it should return by specifying #to_other" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new
      r1 = Neo4j::Relationship.new(:friend, a, b)
      Neo4j::Relationship.new(:friend, a, c)

      a.rels.to_other(b).size.should == 1
      a.rels.to_other(b).should include(r1)
    end

    it "#rels returns an RelationshipTraverser which provides a method for deleting all the relationships" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new
      r1 = Neo4j::Relationship.new(:friend, a, b)
      r2 = Neo4j::Relationship.new(:friend, a, c)

      a.rel?(:friend).should be_true
      a.rels.del
      a.rel?(:friend).should be_false
      new_tx
      r1.exist?.should be_false
      r2.exist?.should be_false
    end

    it "#rels returns an RelationshipTraverser with methods #del and #to_other which can be combined to only delete a subset of the relationships" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new
      r1 = Neo4j::Relationship.new(:friend, a, b)
      r2 = Neo4j::Relationship.new(:friend, a, c)
      r1.exist?.should be_true
      r2.exist?.should be_true

      a.rels.to_other(c).del
      new_tx
      r1.exist?.should be_true
      r2.exist?.should be_false
    end

  end


end