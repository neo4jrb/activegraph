require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::EventHandler, :type => :transactional do
  def event_receiver(meth)
    rec = Object.new
    singelton = class << rec;
      self;
    end

    singelton.send(:define_method, meth) do |*args|
      @args ||= []
      @args << args
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
      @args.size
    end

    rec
  end

  it "#on_node_created is called once every time a node is created" do
    rec = event_receiver(:on_node_created)
    Neo4j.event_handler.add rec
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    finish_tx
    rec.arg0.should  include(node1)
    rec.arg0.should  include(node2)
    rec.calls.should == 2
  end

  it "#on_node_deleted is called once every time a node is deleted" do
    rec = event_receiver(:on_node_deleted)
    Neo4j.event_handler.add rec
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    new_tx
    node1.del
    node2.del
    finish_tx
    rec.calls.should == 2
    rec.arg0.should  include(node1)
    rec.arg0.should  include(node2)
  end


  it "#on_property_changed is called once every time a node is deleted" do
    node1 = Neo4j::Node.new
    node2 = Neo4j::Node.new
    node1[:name] = 'node1'
    node1[:foo] = 'bar1'
    node2[:name] = 'node2'
    node2[:foo] = 'bar2'

    new_tx

    rec = event_receiver(:on_property_changed)
    Neo4j.event_handler.add rec

    node1[:name] = 'a_node1'
    node2[:name] = 'a_node2'
    node2[:foo] = 'a_bar2'
    finish_tx
    rec.calls.should == 3
    rec.arg0.should  include(node1)
    rec.arg0.should  include(node2)
    rec.arg1.should == %w[name name foo]
    rec.arg2.should == %w[node1 node2 bar2]
    rec.arg3.should == %w[a_node1 a_node2 a_bar2]
  end

end
