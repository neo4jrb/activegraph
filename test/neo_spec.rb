# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'neo'


describe Neo do
  before(:all) do
    Neo::start
  end

  after(:all) do
    Neo::stop
  end  
  
  it "should not find a meta node of a class that does not exist" do
    n = Neo::find_meta_node('Kalle')
    n.should be_nil
  end
  
  it "should find the meta node of a class that exists" do
    class Kalle < Neo::Node 
    end
    
    n = Neo::find_meta_node('Kalle')
    n.should_not be_nil
    n.should be_kind_of(Neo::MetaNode)
  end
 
end


describe Neo::MetaNode do
  before(:all) do
    Neo::start
  end

  after(:all) do
    Neo::stop
  end  

  it "should find all instances of a class" 
end 


describe Neo::Node do
  before(:all) do
    Neo::start
  end

  after(:all) do
    Neo::stop
  end  

  it "should construct a new node in a transaction"  do
    node = nil
    Neo::transaction {
      node = Neo::Node.new
    }
    node.should be_an_instance_of(Neo::Node)
  end

  it "should run in a transaction if a block is given at new"  do
    node = Neo::Node.new { }
    node.should be_an_instance_of(Neo::Node)
  end
  
  it "should allow to create a node from a native Neo Java object" do
    node1 = Neo::Node.new { }
    node2 = Neo::Node.new(node1.internal_node)
    
    node1.internal_node.should be_equal(node2.internal_node)
  end
  
  
  it "should have a property for the name of the ruby class it represent" do
    node1 = Neo::Node.new { }
    node1.classname.should be == "Neo::Node"
    
    class FooBar < Neo::Node
    end
    
    node2 = FooBar.new {}
    node2.classname.should be == "FooBar"    
  end

  it "should have a meta node for each class" do
    class Kalle < Neo::Node 
    end
    
    meta_node = Kalle.meta_node 
    meta_node.should be_kind_of(Neo::MetaNode)
  end

  it "should have setter and getters for any property" do
    #given
    node = Neo::Node.new do |n|
      n.foo = "foo"
      n.bar = "foobar"
    end
    
    # then
    node.foo.should == "foo"
    node.bar.should == "foobar"
  end
  

  it "should allow to declare properties"  do
    # given
    class Person < Neo::Node
      properties :name, :age 
    end
    
    # when
    person = Person.new {|node|
      node.name = "kalle"
      node.age = 42
    }
    
    # then
    person.name.should == "kalle"
    person.age.should == 42
  end

  it "should create a meta node for each new subclass of Node" do
    # when
    class FooBar < Neo::Node
    end
    
    # then
    metanode = Neo::meta_nodes.nodes.find{|node| node.meta_classname == 'FooBar'}
    metanode.should be_kind_of(Neo::Node)
  end
  

  it "should have subclasses that have references to a MetaNode" do
    # when
    class FooBar < Neo::Node
    end
    
    # then
    metanode = Neo::meta_nodes.nodes.find{|node| node.meta_classname == 'FooBar'}
    metanode.should be_kind_of(Neo::Node)
  end
  
  it "should have generated setter and getters for declared properties" do
    # given
    class Person < Neo::Node
      properties :my_property
    end

    # when
    p = Person.new {}
    
    # then
    p.methods.should include("my_property")
    p.methods.should include("my_property=")
  end

  it "should have generated setter and getters for subclasses as well" do
    # given
    class Person < Neo::Node
      properties :my_property
    end

    class Employee < Person
      properties :salary
    end

    # when
    p = Employee.new {}
    
    # then
    p.methods.should include("my_property")
    p.methods.should include("my_property=")
    p.methods.should include("salary")
    p.methods.should include("salary=")
  end
  
  
#  it "should allow to declare relations" do
#    #given
#    class Person < Neo::Node
#      properties :name, :age 
#      relations :friends
#    end
#
#    p = Person.new {}    
#    puts "Method: " + p.instance_method.to_s
#  end

    it "should allow to add relations" do
    #given
    class Person < Neo::Node
      properties :name, :age 
      relations :friends
    end
    
    p1 = Person.new do|node|
       node.name = "p1"
    end

    # then    
    p2 = Person.new do|node|
       node.name = "p2"
       node.friends << p1
    end
  end
  
  it "should allow to dynamically add relations" do
    Neo::transaction {
      node1 = Neo::Node.new    
      node2 = Neo::Node.new    
     
      Neo::Node.add_relation_type(:foos)
      
      node2.foos << node1
    }
  end


  it "should have relationship getters that returns Enumerable objects" do
    #given
    class Person < Neo::Node
      properties :name, :age 
      relations :friends
    end
    
    # when
    p1 = Person.new do |node|
       node.name = "p1"
    end

    p2 = Person.new do |node|
       node.name = "p2"
       node.friends << p1
    end
    
    # then
    p2.friends.should be_kind_of(Enumerable)
    found = p2.friends.find{|node| node.name == 'p1'}
    found.name.should == "p1"
    found.should be_kind_of(Person)
  end
  
end
