require File.join(File.dirname(__FILE__), 'spec_helper')

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
    it "raise an exception if node was already deleted. Finish Transaction will also raise an exception" do
      new_node = Neo4j::Node.new
      new_node.del.should be_nil
      lambda{ new_node.del }.should raise_error
      lambda{ finish_tx }.should raise_error
    end

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

end