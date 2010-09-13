require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, :type=> :transactional do



  before(:each) do
    SimpleNode.index(:city)  # TODO
  end

  after(:each) do
    SimpleNode.rm_index(:city)     # TODO
  end


  it "#new :name => 'foo' ..." do
    n = SimpleNode.new :name => 'foo', :bar => 'bar'
    n.name.should == 'foo'
    n[:bar].should == 'bar'

  end
  it "#[] and #[]= read and sets a neo4j property" do
    n = SimpleNode.new
    n.name = 'kalle'
    n.name.should == 'kalle'
  end


  it "Neo4j::Node.load loads the correct class" do
    n1 = SimpleNode.new
    n2 = Neo4j::Node.load(n1.id)
    # then
    n1.should == n2
  end

  it "#index should add an index" do
    n = SimpleNode.new
    n[:city] = 'malmoe'
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    SimpleNode.find(:city, 'malmoe').first.should == n
  end


  it "#index should keep the index in sync with the property value" do
    n = SimpleNode.new
    n[:city] = 'malmoe'
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    n[:city] = 'stockholm'
    Neo4j::Transaction.finish
    Neo4j::Transaction.new

    SimpleNode.find(:city, 'malmoe').first.should_not == n
    SimpleNode.find(:city, 'stockholm').first.should == n
  end


end