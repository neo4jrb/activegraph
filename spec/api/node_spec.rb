require 'spec_helper'

# http://blog.davidchelimsky.net/2010/07/01/rspec-2-documentation/
# http://asciicasts.com/episodes/157-rspec-matchers-macros
#http://kpumuk.info/ruby-on-rails/my-top-7-rspec-best-practices/
# http://eggsonbread.com/2010/03/28/my-rspec-best-practices-and-tips/
# http://www.slideshare.net/gsterndale/straight-up-rspec
#org.neo4j.kernel.impl.core.NodeProxy.class_eval do
#end

class DummyNode
  attr_accessor :props
  def initialize
    @props = {}
  end
  
  def set_property(p,v)
    @props[p] = v
  end
end

describe Neo4j::Node do


  instance_methods do


  end


  static_methods do

    new(arg(:db)) do
      Description "Creates a new node with the given database instance"
      Given do
        db = double("EmbeddedGraphDatabase")
        fixtures[:new_node] = double("Node")
        db.should_receive(:create_node).and_return(fixtures[:new_node])
        arg.db = db
      end
      Return  do
        it ("a new node"){ should == fixtures[:new_node]}
      end
    end

                      
    new() do
      Description "Creates a new node using the default database instance"
      Given do
        db = double("EmbeddedGraphDatabase")
        Neo4j.stub!(:instance).and_return(db)
        fixtures[:new_node] = double("Node")
        db.should_receive(:create_node).and_return(fixtures[:new_node])
      end
      Return  do
        it ("a new node"){ should == fixtures[:new_node]}
      end
    end


    new(arg(:hash)) do
      Description "Creates a new node and initialize it with the given hash"
      Given do
        db = double("EmbeddedGraphDatabase")
        Neo4j.stub!(:instance).and_return(db)
        fixtures[:new_node] = DummyNode.new
        db.should_receive(:create_node).and_return(fixtures[:new_node])
        arg.hash = {:name => 'andreas', :colour => 'blue'}
      end
      Return  do
        it ("a new node"){ should == fixtures[:new_node] }
        it ("a node with properties set from the given hash"){ subject.props['name'].should == arg.hash[:name]}
      end
    end


    load(arg(:node_id)) do
      Description "Loads an existing node if it exists, otherwise returns nil"
      Scenario "The node exists" do
        Given do
          db = double("EmbeddedGraphDatabase")
          Neo4j.stub!(:instance).and_return(db)
          fixtures[:a_node] = DummyNode.new
          db.should_receive(:get_node_by_id).with(2).and_return(fixtures[:a_node])
          arg.node_id = 2
        end
        Return do
          it "the existing node" do
            should == fixtures[:a_node]
          end
        end
      end

      Scenario "The node not exists" do
        Given do
          db = double("EmbeddedGraphDatabase")
          Neo4j.stub!(:instance).and_return(db)
          fixtures[:a_node] = DummyNode.new
          db.should_receive(:get_node_by_id).with(2).and_raise(org.neo4j.graphdb.NotFoundException.new)
          arg.node_id = 2
        end
        Return do
          it { should == nil}
        end
      end

    end
  end
end
