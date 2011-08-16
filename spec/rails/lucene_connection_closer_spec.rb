require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe Neo4j::Rails::LuceneConnectionCloser do
  it "always calls close_lucene_connections" do
    app = mock('app')
    closer = Neo4j::Rails::LuceneConnectionCloser.new(app)
    Neo4j::Rails::Model.should_receive(:close_lucene_connections).at_least(:once)
    app.should_receive(:call).and_raise(Exception.new("oops"))

    lambda {closer.call('foo')}.should raise_exception

  end
end