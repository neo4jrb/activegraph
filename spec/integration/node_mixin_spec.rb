require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::NodeMixin, "inheritance", :type=> :transactional do

  before(:all) do
    person_class = create_node_mixin do
      property :name
      has_n :friends
      index :name
    end

    @employee_class = create_node_mixin_subclass(person_class) do
      property :employee_id
      has_n :contracts
    end
  end

  it "#new creates node and set properties with given hash" do
    empl = @employee_class.new(:name => 'andreas', :employee_id => 123)
    empl[:name].should == 'andreas'
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

  context "property :born => Date" do
    before(:all) do
      @clazz = create_node_mixin do
        property :born, :type => Date
        index :born
      end
    end

    it "should save the date as an Fixnum" do
      v = @clazz.new :born => Date.today
      val = v._java_node.get_property('born')
      val.class.should == Fixnum
    end

    it "should load the date as an Date" do
      now = Date.today
      v = @clazz.new :born => now
      v.born.should == now
    end

    it "can be ranged searched: find(:born).between(date_a, Date.today)" do
      yesterday = Date.today - 1
      v = @clazz.new :born => yesterday
      new_tx
      found = [*@clazz.find(:born).between(Date.today-2, Date.today)]
      found.size.should == 1
      found.should include(v)
    end
  end


  context "property :since => DateTime" do
    before(:all) do
      @clazz = create_node_mixin do
        property :since, :type => DateTime
        index :since
      end
    end

    it "should save the date as an Fixnum" do
      v = @clazz.new :since => DateTime.new(1842, 4, 2, 15, 34, 0)
      val = v._java_node.get_property('since')
      val.class.should == Fixnum
    end

    it "should load the date as an Date" do
      since = DateTime.new(1842, 4, 2, 15, 34, 0)
      v = @clazz.new :since => since
      v.since.should == since
    end

    it "can be ranged searched: find(:born).between(date_a, Date.today)" do
      a = DateTime.new(1992, 1, 2, 15, 20, 0)
      since = DateTime.new(1992, 4, 2, 15, 34, 0)
      b = DateTime.new(1992, 10, 2, 15, 55, 0)
      v = @clazz.new :since => since
      new_tx
      found = [*@clazz.find(:since).between(a, b)]
      found.size.should == 1
      found.should include(v)
    end
  end

end
