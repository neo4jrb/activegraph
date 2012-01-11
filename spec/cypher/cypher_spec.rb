require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j#query (cypher)" do

  before(:all) do
    new_tx
    @a = Neo4j::Node.new :name => 'a'
    @b = Neo4j::Node.new :name => 'b'
    @r = Neo4j::Relationship.new(:bar, @a, @b)
    finish_tx
  end

  describe "returning one node" do
    before(:all) do
      @query_result = Neo4j.query("START n=node(0) RETURN n")
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == 'n'
    end

    it "its first value is hash" do
      r = @query_result.to_a  # can only loop once
      r.size.should == 1
      r.first.should include('n')
      r.first['n'].class.should == Neo4j::Node
      r.first['n'].neo_id.should == 0
    end
  end

  describe "returning one relationship" do
    before(:all) do
      @query_result = Neo4j.query("START n=relationship({rel}) RETURN n", 'rel' => @r.neo_id)
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == 'n'
    end

    it "its first value is hash" do
      r = @query_result.to_a
      r.size.should == 1
      r.first.should include('n')
      r.first['n'].class.should == Neo4j::Relationship
      r.first['n'].neo_id.should == @r.neo_id
    end
  end

  describe "returning one wrapped node" do
    class MyCypherNode
      include Neo4j::NodeMixin
    end

    before(:all) do
      @node = Neo4j::Transaction.run{ MyCypherNode.new}
      @query_result = Neo4j.query("START n=node({node}) RETURN n", 'node' => @node.neo_id)
    end
    it "its first value is hash" do
      r = @query_result.to_a

      r.size.should == 1
      r.first.should include('n')
      r.first['n'].class.should == MyCypherNode
      r.first['n'].neo_id.should == @node.neo_id
    end
  end

  describe "returning one wrapped relationship" do
    class MyCypherRel
      include Neo4j::RelationshipMixin
    end

    before(:all) do
      @rel = Neo4j::Transaction.run{ MyCypherRel.new(:foo, @a,@b)}
      @query_result = Neo4j.query("START n=relationship({rel}) RETURN n", 'rel' => @rel.neo_id)
    end

    it "its first value is hash" do
      r = @query_result.to_a  # can only loop once
      r.size.should == 1
      r.first.should include('n')
      r.first['n'].class.should == MyCypherRel
      r.first['n'].neo_id.should == @rel.neo_id
    end
  end

  describe "returning several nodes" do
    before(:all) do
      @query_result = Neo4j.query("START n=node(#{@a.neo_id}, #{@b.neo_id}) RETURN n")
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == 'n'
    end

    it "its first value is hash" do
      r = @query_result.to_a  # can only loop once
      r.size.should == 2
      r.first.should include('n')
      r[0]['n'].neo_id.should == @a.neo_id
      r[1]['n'].neo_id.should == @b.neo_id
    end
  end

  describe "a query with parameters" do
    it "should work" do
      @query_result = Neo4j.query('START n=node({a}) RETURN n', {'a' => @a.neo_id})
      @query_result.to_a.size.should == 1
    end

  end


  describe "a query with a lucene index" do

    class FooBarCypher < Neo4j::Rails::Model
      property :name
      index :name
    end

    before(:all) do
      @foo = FooBarCypher.create!(:name => 'foo')
      @bar = FooBarCypher.create!(:name => 'bar')
      @andreas = FooBarCypher.create!(:name => 'andreas')
    end

    it "can use the lucene index" do
      index_name = FooBarCypher.index_names[:exact]
      query = %Q[START n=node:#{index_name}("name:foo") RETURN n]
      @query_result = Neo4j.query(query)
      r = @query_result.to_a  # can only loop once
      r.size.should == 1
      r.first['n'].wrapper.should == @foo
    end
  end
end
