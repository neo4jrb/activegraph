require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "inheritance", :type=> :transactional do
  it "#new creates node and set properties with given hash" do
    empl = Employee.new(:name => 'andreas', :employee_id => 123)
    empl[:name].should == 'andreas'
  end

  it "#has_n can use baseclass definition" do
    empl = Employee.new
    node =  Neo4j::Node.new
    empl.friends << node
    empl.friends.should include(node)
  end

end


describe Neo4j::NodeMixin, :type=> :transactional do

  before(:each) do
    SimpleNode.index(:city)  # TODO
  end

  after(:each) do
    SimpleNode.rm_index_type     # TODO
  end



  it "#new :name => 'foo' initialize the node with given property hash" do
    n = SimpleNode.new :name => 'foo', :bar => 'bar'
    n.name.should == 'foo'
    n[:bar].should == 'bar'
  end

  it "#init_on_create is called when node is created and can be used to initialize it" do
    n = NodeWithInitializer.new('kalle', 'malmoe')
    n.name.should == 'kalle'
    n.city.should == 'malmoe'
  end


  it "#[] and #[]= read and sets a neo4j property" do
    n = SimpleNode.new
    n.should respond_to(:name)
    n.should respond_to(:city)
    n.name = 'kalle'
    n.name.should == 'kalle'
    n.city = 'malmoe'
    n.city.should == 'malmoe'
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

    new_tx

    SimpleNode.find('city: malmoe').first.should == n
  end


  it "#index should keep the index in sync with the property value" do
    n = SimpleNode.new
    n[:city] = 'malmoe'

    new_tx

    n[:city] = 'stockholm'

    new_tx

    SimpleNode.find('city: malmoe').first.should_not == n
    SimpleNode.find('city: stockholm').first.should == n
  end


end