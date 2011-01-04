require File.join(File.dirname(__FILE__), '..', 'spec_helper')


#
# See also the node_spec.rb for traversal using outgoing and incoming and both
#
describe Neo4j::Node, :type => :transactional do
  before(:each) do
    new_tx
    @x = Neo4j::Node.new :name => 'x'
    @a = Neo4j::Node.new :name => 'a'
    @b = Neo4j::Node.new :name => 'b'
    @c = Neo4j::Node.new :name => 'c'
    @d = Neo4j::Node.new :name => 'd'
    @e = Neo4j::Node.new :name => 'e'
    @f = Neo4j::Node.new :name => 'f'
    @y = Neo4j::Node.new :name => 'y'
  end


  describe "#expand" do

    it "can be used to select relationships based on relationship properties" do
      Neo4j::Relationship.new(:friends, @x, @a, :age => 1)
      Neo4j::Relationship.new(:friends, @x, @b, :age => 10)
      Neo4j::Relationship.new(:friends, @b, @c, :age => 1)
      Neo4j::Relationship.new(:friends, @b, @d, :age => 10)

      res = @x.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.depth(:all).to_a
      res.should include(@b, @d)
      res.size.should == 2
    end

    it "default is depth(1) traversals" do
      Neo4j::Relationship.new(:friends, @x, @a, :age => 1)
      Neo4j::Relationship.new(:friends, @x, @b, :age => 10)
      Neo4j::Relationship.new(:friends, @b, @c, :age => 1)
      Neo4j::Relationship.new(:friends, @b, @d, :age => 10)

      res = @x.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.to_a
      res.should include(@b)
      res.size.should == 1
    end
    
    it "returns nothing when expand returns an empty array" do
      Neo4j::Relationship.new(:friends, @x, @a)
      Neo4j::Relationship.new(:friends, @x, @b)
      Neo4j::Relationship.new(:friends, @b, @c)
      Neo4j::Relationship.new(:friends, @b, @d)
      res = @x.expand { |*| []}.depth(:all)
      res.should be_empty
    end

  end
end
