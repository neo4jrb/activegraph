# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'neo'
require 'fileutils'  


# ------------------------------------------------------------------------------
# Utility methods

DB_LOCATION = 'var/neo'

def start
  FileUtils.rm_r DB_LOCATION if File.directory?(DB_LOCATION)
  Neo::NeoService.instance.start(DB_LOCATION)
end


def stop
  Neo::NeoService.instance.stop
  FileUtils.rm_r DB_LOCATION if File.directory?(DB_LOCATION)
end


# ------------------------------------------------------------------------------
# Shared examples
# TODO add more behaviours and use it more
shared_examples_for "Node" do
  it "should have a to_s method" do
    @node.should respond_to(:to_s)
    @node.to_s.should be_kind_of(String)
  end
end


# ------------------------------------------------------------------------------
# the following specs are run when doing  a rollback in one transaction 
# 


describe "When doing a rollback in one transaction" do
  before(:all) do
    start
  end
  
  after(:all) do
    stop
  end  


  it "should not change properties" do
    # given
    node = Neo::Node.new {|n| n.foo = 'foo'}

    # when
    Neo::transaction { |t|
      node.foo = "changed"

      # when doing rollback
      t.failure
    }
    
    # then
    Neo::transaction { 
      node.foo.should == 'foo'
    }
  end
    
  it "should not create a meta class" do
    # given
    Neo::transaction { |t|
      class FooBar1 < Neo::Node
      end

      # when doing rollback
      t.failure
    }
    
    # then
    Neo::transaction {
      metanode = Neo::neo_service.find_meta_node('FooBar1')
      metanode.should be_nil
    }
  end
  
end


# ------------------------------------------------------------------------------
# the following specs are not always run inside ONE Neo transaction
# 

describe "When neo has been restarted" do

  def restart
    Neo::neo_service.stop
    Neo::neo_service.start DB_LOCATION
  end
  
  describe Neo::NeoService do
    before(:all) do
      start
    end

    after(:all) do
      stop
    end  
    
    it "should contain referenses to all meta nodes" do
      # given
      Neo::transaction {
        metas = Neo::neo_service.meta_nodes.nodes
        metas.to_a.size.should == 0
      }
      
      class Foo < Neo::Node
      end
      
      
      Neo::transaction {
        metas = Neo::neo_service.meta_nodes.nodes
        metas.to_a.size.should == 1
        meta = Neo::neo_service.find_meta_node('Foo')
        meta.should_not be_nil
        meta.meta_classname.should == "Foo"
      }
      
      # when 
      restart
      
      # then
      Neo::transaction {
        metas = Neo::neo_service.meta_nodes.nodes
        metas.to_a.size.should == 1
        meta = Neo::neo_service.find_meta_node('Foo')
        meta.should_not be_nil
        meta.meta_classname.should == "Foo"
      }
      
      
    end
    
    it "should have unique node ids for the Meta Node" do
      # when Neo is restarted make sure that the node representing the class
      # has the same node_id
    
      class Foo < Neo::Node
      end

      id1 = nil
      Neo::transaction {
        id1 = Neo::neo_service.find_meta_node('Foo').neo_node_id
      }

      restart
      
      id2 = nil
      Neo::transaction {
        id2 = Neo::neo_service.find_meta_node('Foo').neo_node_id
      }
      id1.should == id2
    end
    
    it "should load node using its id" do
      node = Neo::Node.new {|n|
        n.baaz = "hello"
      }
      
      restart
      
      Neo::transaction {
        node2 = Neo::neo_service.find_node(node.neo_node_id)
        node.baaz.should == "hello"
      }
    end
  end 
end

# ------------------------------------------------------------------------------
# the following specs are run inside one Neo transaction
# 

describe "When running in one transaction" do
  before(:all) do
    start
  end

  after(:all) do
    stop
  end  
  
  before(:each) do
    @transaction = Neo::transaction.begin 
  end
  
  after(:each) do
    @transaction.failure # do not want to store anything
    @transaction.finish
  end


  # ------------------------------------------------------------------------------
  # MetaNode
  # 

  describe Neo::MetaNode do
    before(:all) do
      class FooBar43 < Neo::Node
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
  end
  
  # ------------------------------------------------------------------------------
  # NeoService
  # 

  describe Neo::NeoService do
  
    it "should not find a meta node of a class that does not exist" do
      n = Neo::NeoService.instance.find_meta_node('Kalle')
      n.should be_nil
    end
  
    it "should find the meta node of a class that exists" do
      class Kalle < Neo::Node 
      end
    
      n = Neo::NeoService.instance.find_meta_node('Kalle')
      n.should_not be_nil
      n.should be_kind_of(Neo::MetaNode)
    end
 
    it "should find an (ruby) object stored in neo given its unique id" do
      class Foo45 < Neo::Node
      end

      foo1 = Foo45.new
      foo2 = Neo::neo_service.find_node(foo1.neo_node_id)
      foo1.neo_node_id.should == foo2.neo_node_id
    end
    #node = Neo::find_node(id) ...
  
  end


  # ----------------------------------------------------------------------------
  # Creating a new Neo node should ...
  #

  
  describe Neo::Node, '(creating a new)' do
 
    it "should allow constructor with no arguments"  do
      node = Neo::Node.new
      node.should be_an_instance_of(Neo::Node)
    end
  
    it "should allow to set any properties in a block"  do
      node = Neo::Node.new { |node|
        node.foo = "foo"
      }
      node.foo.should == "foo"
    end
    
    it "should allow to create a node from a native Neo Java object" do
      node1 = Neo::Node.new
      node2 = Neo::Node.new(node1.internal_node)
    end
  end
  
  
  
  # ----------------------------------------------------------------------------
  # A created Neo node should ...
  #
  
  describe Neo::Node, '(a newly created one)' do
    
    before(:each) do
      @node = Neo::Node.new
    end

    it "should be == another node only if it has the same node id" do
      node2 = Neo::Node.new(@node.internal_node)
      @node.internal_node.should be_equal(node2.internal_node)
      @node.should == node2
      @node.hash.should == node2.hash
    end
    
    
    it "should have a neo id" do
      @node.neo_node_id.should be_kind_of(Fixnum)
    end

    it "should know the name of the ruby class it represent" do
      @node.classname.should be == "Neo::Node"
    end
    
    it "should allow to dynamically add relations" do
      node2 = Neo::Node.new    
      
      # add a relationship to all nodes named 'foos'
      Neo::Node.add_relation_type(:foos)
      
      node2.foos << @node
    end

    it "should allow to change properties" do
      # given
      node = Neo::Node.new { |n| n.baaz = "Baaz"}
      
      # when
      node.baaz = "Changed it"
      
      # then
      node.baaz.should =='Changed it'
    end
    
    it "should not be possible to add to a relationship a none Neo::Node"
    
    it "should not be possible to set a neo property that is not a string of fixnum"

  end

  
  # ----------------------------------------------------------------------------
  # When inherit from Neo::Node it should ...
  #
  
  describe Neo::Node, '(when inherit from it)' do
    
    it "should know the name of the ruby class it represent" do
      class FooBar3 < Neo::Node
      end
      
      node2 = FooBar3.new
      node2.classname.should be == "FooBar3"    
    end
  
    it "should have a meta node for each class" do
      class Kalle < Neo::Node 
      end
      
      meta_node = Kalle.meta_node 
      meta_node.should_not be_nil
      meta_node.should be_kind_of(Neo::MetaNode)
    end
  
  
    it "should allow to declare properties"  do
      # given
      class Person0 < Neo::Node
        properties :name, :age 
      end
      
      # when
      person = Person0.new {|node|
        node.name = "kalle"
        node.age = 42
      }
      
      # then
      person.name.should == "kalle"
      person.age.should == 42
    end
  
    it "should have subclasses that have references to a MetaNode" do
      # when
      class FooBar4 < Neo::Node
      end
      
      # then
      metanode = Neo::neo_service.find_meta_node('FooBar4')
      metanode.should be_kind_of(Neo::MetaNode)
    end
    
    it "should have generated setter and getters for declared properties" do
      # given
      class Person1 < Neo::Node
        properties :my_property
      end
  
      # when
      p = Person1.new {}
      
      # then
      p.methods.should include("my_property")
      p.methods.should include("my_property=")
    end
  
    it "should have generated setter and getters for subclasses as well" do
      # given
      class Person2 < Neo::Node
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
      class Person3 < Neo::Node
        properties :name, :age 
        relations :friends
      end
  
      person = Person3.new    
      person.methods.should include("friends")
    end
  
    it "should allow to add relations" do
      #given
      class Person4 < Neo::Node
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
    
  
  
    it "should have relationship getters that returns Enumerable objects" do
      #given
      class Person5 < Neo::Node
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
    
    
  end
end
