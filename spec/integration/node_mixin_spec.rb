require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "inheritance", :type=> :transactional do
  before(:each) do
    Employee.index(:employee_id)
    Employee.index(:name)
  end

  after(:each) do
    Employee.clear_index_type
    Employee.rm_index_type
    Person.clear_index_type
    Person.rm_index_type
  end

  it "#new creates node and set properties with given hash" do
    empl = Employee.new(:name => 'andreas', :employee_id => 123)
    empl[:name].should == 'andreas'
  end

  it "#index can use an index from a base class" do
    empl = Employee.new(:name => 'ronge', :employee_id => 123)
    empl[:name].should == 'ronge'

    new_tx

    Employee.find('name: ronge').first.should == empl
    Employee.find('employee_id: 123').first.should == empl
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
    SimpleNode.clear_index_type
    SimpleNode.rm_index_type     # TODO
  end



  it "#new :name => 'foo' initialize the node with given property hash" do
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