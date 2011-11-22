require File.join(File.dirname(__FILE__), 'spec_helper')

describe Neo4j::EventHandler, :type => :transactional do
  class TestModel
    include Neo4j::NodeMixin
    property :name
  end

  def event_receiver(meth, &block)
    @rec      = Object.new
    singelton = class << @rec;
      self;
    end

    singelton.send(:define_method, meth) do |*args|
      @args ||= []
      @args << args
      block.call(*args) if block
    end

    singelton.send(:define_method, "args") do
      @args
    end

    (0..4).each do |i|
      singelton.send(:define_method, "arg#{i}") do
        @args.nil? ? [] : @args.collect { |a| a[i] }
      end
    end

    singelton.send(:define_method, :calls) do
      @args.nil? ? 0 : @args.size
    end

    Neo4j.event_handler.add @rec
    @rec
  end

  after(:each) { Neo4j.event_handler.remove(@rec) if @rec }

  it "#on_node_created is called once every time a node is created" do
    rec   = event_receiver(:on_node_created)

    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    finish_tx
    rec.arg0.should include(node1)
    rec.arg0.should include(node2)
    rec.calls.should == 2
  end


  it "#on_property_changed is not called when a node is created" do
    rec = event_receiver(:on_property_changed)

    Neo4j::Node.new
    Neo4j::Node.new
    finish_tx
    rec.calls.should == 0
  end

  it "#on_node_deleted is called once every time a node is deleted" do
    rec   = event_receiver(:on_node_deleted)
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    new_tx
    node1.del
    node2.del
    finish_tx
    rec.calls.should == 2
    rec.arg0.should include(node1)
    rec.arg0.should include(node2)
  end

  it "#on_property_changed will not be called when a node is deleted" do
    rec   = event_receiver(:on_property_changed)
    node1 = Neo4j::Node.new
    new_tx
    node1.del
    finish_tx
    rec.calls.should == 0
  end

  it "#on_node_deleted will receive an hash of all properties the node had before it was deleted" do
    rec   = event_receiver(:on_node_deleted)
    node1 = Neo4j::Node.new :name => 'node1', :age => 42
    new_tx
    node1.del
    finish_tx
    rec.calls.should == 1
    rec.arg0.should include(node1)
    rec.arg1[0].should == {'name' => 'node1', 'age' => 42}
  end

  it "in callbacks it is possible to modify any nodes" do
    node1        = Neo4j::Node.new
    node2        = Neo4j::Node.new

    node1.outgoing(:foo) << node2
    new_tx

    event_receiver(:on_property_changed) do |node, *|
      node2.del
      node[:foo] = '123'
    end

    node1[:name] = 'kalle'
    finish_tx

    node2.should_not exist
    node1[:foo].should == '123'
  end

  it "#on_property_changed is called once every time a node is deleted" do
    node1        = Neo4j::Node.new
    node2        = Neo4j::Node.new
    node1[:name] = 'node1'
    node1[:foo]  = 'bar1'
    node2[:name] = 'node2'
    node2[:foo]  = 'bar2'

    new_tx

    rec          = event_receiver(:on_property_changed)
    Neo4j.event_handler.add rec

    node1[:name] = 'a_node1'
    node2[:name] = 'a_node2'
    node2[:foo]  = 'a_bar2'
    finish_tx
    rec.calls.should == 3
    rec.arg0.should include(node1)
    rec.arg0.should include(node2)
    rec.arg1.should == %w[name name foo]
    rec.arg2.should == %w[node1 node2 bar2]
    rec.arg3.should == %w[a_node1 a_node2 a_bar2]
  end


  it "#on_relationship_created is called every time a relationship is created" do
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new

    rel   = Neo4j::Relationship.new(:friends, node1, node2)

    rec   = event_receiver(:on_relationship_created)
    Neo4j.event_handler.add rec

    new_tx

    rec.calls.should == 1
    rec.arg0.should include(rel)
  end

  it "#on_relationship_deleted is called every time a relationship is deleted" do
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    rel   = Neo4j::Relationship.new(:friends, node1, node2)

    new_tx
    rec   = event_receiver(:on_relationship_deleted)
    Neo4j.event_handler.add rec

    # when
    rel.del
    finish_tx

    # then
    rec.calls.should == 1
    rec.arg0.should include(rel)
  end

  it "#classes_changed should be called once for all added nodes" do

    model1 = TestModel.new(:name => 'one')
    model2 = TestModel.new(:name => 'two')

    rec   = event_receiver(:classes_changed)
    Neo4j.event_handler.add rec
    # when
    new_tx

    # then
    rec.calls.should == 1
    rec.arg0.size.should == 1
    rec.arg0[0].get("TestModel").added.size.should == 2
    rec.arg0[0].get("TestModel").added.should include(model1,model2)
    rec.arg0[0].get("TestModel").deleted.size.should == 0
    rec.arg0[0].get("TestModel").net_change.should == 2
  end

  it "#classes_changed should be called once for all deleted nodes" do

    model1 = TestModel.new(:name => 'one')
    model2 = TestModel.new(:name => 'two')

    # when
    new_tx

    model1.del
    model2.del

    rec   = event_receiver(:classes_changed)
    Neo4j.event_handler.add rec
    finish_tx

    # then
    rec.calls.should == 1
    rec.arg0.size.should == 1
    rec.arg0[0].get("TestModel").added.size.should == 0
    rec.arg0[0].get("TestModel").deleted.size.should == 2
    rec.arg0[0].get("TestModel").deleted.should include(model1,model2)
    rec.arg0[0].get("TestModel").net_change.should == -2
  end

end