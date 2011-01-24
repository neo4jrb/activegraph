require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Node, :type => :transactional do

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
      new_node[:key] = [1, 2, 3]
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
end
