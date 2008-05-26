# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'neo4j'
require 'spec_helper'



# ------------------------------------------------------------------------------
# Shared examples
# TODO add more behaviours and use it more
shared_examples_for "Node" do
  it "should have a to_s method" do
    @node.should respond_to(:to_s)
    @node.to_s.should be_kind_of(String)
  end
  
  it "should be == another node only if it has the same node id" do
    clazz = @node.class
    node2 = clazz.new(@node.internal_node)
    @node.internal_node.should be_equal(node2.internal_node)
    @node.should == node2
    @node.hash.should == node2.hash
  end
    

  it "should know all its properties" do
    @node.p1 = "val1"
    @node.p2 = "val2"
    
    @node.props.should have_key('p1')
    @node.props.should have_key('p2')
  end
  
  
  it "should have a neo id" do
    @node.neo_node_id.should be_kind_of(Fixnum)
  end

  it "should know the name of the ruby class it represent" do
    @node.classname.should be == @node.class.to_s
  end
    
  it "should allow to dynamically add any relation type" do
    # add a relationship to all nodes named 'foos'
    @node.class.add_relation_type(:foos)
    added = Neo4j::BaseNode.new
    @node.foos << added
    @node.foos.to_a.should include(added)
  end

  it "should allow to change properties" do
    # given
    @node.baaz = "first"
      
    # when
    @node.baaz = "Changed it"
      
    # then
    @node.baaz.should =='Changed it'
  end
    
  it "can not have a relationship to a none Neo::Node"
    
  it "can not set a property that is not a string of fixnum"
  
end


# ------------------------------------------------------------------------------
# the following specs are run inside one Neo4j transaction
# 

describe "When running in one transaction" do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
  
  before(:each) do
    @transaction = Neo4j::transaction.begin 
  end
  
  after(:each) do
    @transaction.failure # do not want to store anything
    @transaction.finish
  end


  # ------------------------------------------------------------------------------
  # MetaNode
  # 

  describe Neo4j::MetaNode do
    before(:all) do
      class FooBar43 < Neo4j::BaseNode
      end
      
      @node = FooBar43.meta_node
    end
    
    
    it_should_behave_like "Node"
     
    it "should hold all referenses to its instances" do
      fb1 = FooBar43.new
      fb2 = FooBar43.new
      
      all = FooBar43.meta_node.instances.to_a
      all.should include(fb1)
      all.should include(fb2)
      all.size.should == 2
    end
    
    it "should not hold referenses to other instances" do
      class FooBarA < Neo4j::BaseNode; end
      class FooBarB < Neo4j::BaseNode; end
      
      a1 = FooBarA.new
      a2 = FooBarA.new
      b1 = FooBarB.new      
      
      allA = FooBarA.meta_node.instances.to_a
      allA.should include(a1)
      allA.should include(a2)
      allA.size.should == 2
      
      allB = FooBarB.meta_node.instances.to_a
      allB.should include(b1)
      allB.size.should == 1
      allB.should_not include(a1)
    end
    
  end
  
  # ------------------------------------------------------------------------------
  # Neo
  # 

  describe Neo4j::Neo do
  
    it "should not find a meta node of a class that does not exist" do
      n = Neo4j::Neo.instance.find_meta_node('Kalle')
      n.should be_nil
    end
  
    it "should find the meta node of a class that exists" do
      class Kalle < Neo4j::BaseNode 
      end
    
      n = Neo4j::Neo.instance.find_meta_node('Kalle')
      n.should_not be_nil
      n.should be_kind_of(Neo4j::MetaNode)
    end
 
    it "should find an (ruby) object stored in neo given its unique id" do
      class Foo45 < Neo4j::BaseNode
      end

      foo1 = Foo45.new
      foo2 = Neo4j::neo_service.find_node(foo1.neo_node_id)
      foo1.neo_node_id.should == foo2.neo_node_id
    end
    #node = Neo4j::find_node(id) ...
  
  end


  # ----------------------------------------------------------------------------
  # Creating a new Neo4j node should ...
  #

  
  describe Neo4j::BaseNode, '(creating a new)' do
 
    it "should allow constructor with no arguments"  do
      node = Neo4j::BaseNode.new
      node.should be_an_instance_of(Neo4j::BaseNode)
    end
  
    it "should allow to set any properties in a block"  do
      node = Neo4j::BaseNode.new { |node|
        node.foo = "foo"
      }
      node.foo.should == "foo"
    end
    
    it "should allow to create a node from a native Neo Java object" do
      node1 = Neo4j::BaseNode.new
      node2 = Neo4j::BaseNode.new(node1.internal_node)
      node1.internal_node.should == node2.internal_node      
    end
  end

  # hmm, why do i have to call the to_s method here ?
  describe Neo4j::Node.to_s, '(creating a new)' do
    before(:all) do
      class SimpleNodeMixin
        include Neo4j::Node
      end
    end
 
    it "should allow constructor with no arguments"  do
      node = SimpleNodeMixin.new
      node.should be_kind_of(Neo4j::Node)
    end

   it "should allow to declare properties"  do
    # given
    class DummyNode < Neo4j::BaseNode
      properties :name, :age 
    end

    node = DummyNode.new
    node.class.decl_props.should include(:name, :age)
  end

    it "should allow to set any properties in a block"  do
      node = SimpleNodeMixin.new { |node|
        node.foo = "foo"
      }
      node.foo.should == "foo"
    end
    
    it "should allow to create a node from a native Neo Java object" do
      node1 = Neo4j::BaseNode.new
      node2 = SimpleNodeMixin.new(node1.internal_node)
      node1.internal_node.should == node2.internal_node
    end
  end
  
  
  # ----------------------------------------------------------------------------
  # A created Neo4j node using NeoMixin it should ...
  #
  
  describe 'Mixin (a newly created one)' do
    
    before(:each) do
      class Mixin1
        include Neo4j::Node
      end
      @node = Mixin1.new
    end
    
    it_should_behave_like "Node"
  end
  
  # ----------------------------------------------------------------------------
  # A created Neo4j node should ...
  #
  
  describe Neo4j::BaseNode, '(a newly created one)' do
    
    before(:each) do
      @node = Neo4j::BaseNode.new
    end

    it_should_behave_like "Node"
   
  end

  
  # ----------------------------------------------------------------------------
  # When inherit from Neo4j::BaseNode it should ...
  #
  
  describe Neo4j::BaseNode, '(when inherit from it)' do
    
    it "should know the name of the ruby class it represent" do
      class FooBar3 < Neo4j::BaseNode
      end
      
      node2 = FooBar3.new
      node2.classname.should be == "FooBar3"    
    end
  
    it "should have a meta node for each class" do
      class Kalle < Neo4j::BaseNode 
      end
      
      meta_node = Kalle.meta_node 
      meta_node.should_not be_nil
      meta_node.should be_kind_of(Neo4j::MetaNode)
    end
  
  
  
    it "should have subclasses that have references to a MetaNode" do
      # when
      class FooBar4 < Neo4j::BaseNode
      end
      
      # then
      metanode = Neo4j::neo_service.find_meta_node('FooBar4')
      metanode.should be_kind_of(Neo4j::MetaNode)
    end
    
    it "should have generated setter and getters for declared properties" do
      # given
      class Person1 < Neo4j::BaseNode
        properties :my_property
      end
  
      # when
      p = Person1.new {}
      
      # then
      p.methods.should include("my_property")
      p.methods.should include("my_property=")
    end
  
    it "should allow to set and get properties on subclasses" do
      # given
      class Person2 < Neo4j::BaseNode
        properties :my_property
      end
  
      class Employee < Person2
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
    
    
    it "should allow to declare relations" do
      #given
      class Person3 < Neo4j::BaseNode
        properties :name, :age 
        relations :friends
      end
  
      person = Person3.new    
      person.methods.should include("friends")
    end
  
    it "should allow to add relations" do
      #given
      class Person4 < Neo4j::BaseNode
        properties :name, :age 
        relations :friends
      end
      
      p1 = Person4.new do|node|
        node.name = "p1"
      end
  
      # then    
      p2 = Person4.new do|node|
        node.name = "p2"
        node.friends << p1
      end
    end
    
  
  
    it "should be possible find other nodes by using relations" do
      #given
      class Person5 < Neo4j::BaseNode
        properties :name, :age 
        relations :friends
      end
      
      # when
      p1 = Person5.new do |node|
        node.name = "p1"
      end
  
      p2 = Person5.new do |node|
        node.name = "p2"
        node.friends << p1
      end
      
      # then
      p2.friends.should be_kind_of(Enumerable)
      found = p2.friends.find{|node| node.name == 'p1'}
      found.name.should == "p1"
      found.should be_kind_of(Person5)
    end
    
    
    it "should find all instance" do
      class Person6 
        include Neo4j::Node
      end
      
      p1 = Person6.new { |n| n.name = "person1"}
      p2 = Person6.new { |n| n.name = "person2"}

      Person6.all.should include(p1,p2)
      Person6.all.size.should == 2
    end

    it "should find all instance of inherited classes" do
      
      class Person7
        include Neo4j::Node
      end

      class Person8 < Person7
      end
      
      p1 = Person7.new { |n| n.name = "person1"}
      p2 = Person8.new { |n| n.name = "person2"}

      Person7.all.should include(p1,p2)
      Person7.all.size.should == 2
      Person8.all.should include(p2)
      Person8.all.size.should == 1
    end
    
  end
end
