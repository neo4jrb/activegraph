require 'spec_helper'


describe Neo4j::Rails::Middleware, :type => :integration do
  it "always calls close_lucene_connections" do
    app = mock('app')
    closer = Neo4j::Rails::Middleware.new(app)
    Neo4j::Rails::Model.should_receive(:close_lucene_connections).at_least(:once)
    app.should_receive(:call).and_raise(Exception.new("oops"))
    lambda {closer.call('foo')}.should raise_exception
  end

  it "always reset the threadlocal_ref_node" do
    my_ref_node = Neo4j::Rails::Model.create
    Neo4j.threadlocal_ref_node = my_ref_node
    Neo4j.ref_node.should == my_ref_node._java_node

    app = mock('app')
    closer = Neo4j::Rails::Middleware.new(app)
    app.should_receive(:call).and_raise(Exception.new("oops"))
    lambda {closer.call('foo')}.should raise_exception
    Neo4j.ref_node.should == Neo4j.default_ref_node
  end

end