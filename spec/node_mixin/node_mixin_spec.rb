require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "inheritance", :type=> :transactional do

  before(:all) do
    person_class = create_node_mixin do
      property :name
      has_n :friends
      index :name
    end

    @employee_class = create_node_mixin_subclass(person_class) do
      property :employee_id, :ssn
      property :weight, :height, :type => Float
      has_n :contracts
    end
  end

  it "#new creates node and set properties with given hash" do
    empl = @employee_class.new(:name => 'andreas', :employee_id => 123, :ssn => 1000, :height => '6.3')

    empl[:name].should == 'andreas'
    empl.ssn == 1000
    empl.height.class.should == Float
    empl.height.should == 6.3
  end

  it "#has_n can use baseclass definition" do
    empl = @employee_class.new
    node =  Neo4j::Node.new
    empl.friends << node
    empl.friends.should include(node)
  end

end


describe Neo4j::NodeMixin, :type=> :transactional do

  before(:each) do
    SimpleNode.index(:city)  
  end

  after(:each) do
    SimpleNode.rm_field_type(:city)
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

end
