require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class User
  include Neo4j::NodeMixin
  property :age
end

class NewsStory
 include Neo4j::NodeMixin
end



describe "Neo4j::Node#rule", :type => :transactional do


  before(:all) do
    User.rule :all
    User.rule(:old) { age > 10 } # for testing evaluation in the context of a wrapped ruby object
    User.rule(:young) { |node| node[:age]  < 5 }  # for testing using native java neo4j node

    NewsStory.rule :all
    NewsStory.rule(:featured) { |node| node[:featured] == true }
    NewsStory.rule(:embargoed) { |node| node[:publish_date] > 2010 }
  end

  after(:all) do
    new_tx
    User.delete_rules
    NewsStory.delete_rules
    finish_tx
  end


  it "generate instance method: <rule_name>? for each rule" do
    young = User.new :age => 2
    young.should respond_to(:old?)
    young.should respond_to(:young?)
    young.should respond_to(:all?)
  end

  it "instance method <rule_name>?  return true if the rule evaluates to true" do
    young = User.new :age => 2
    old = User.new :age => 20

    young.should be_young
    old.should be_old
  end

  it "generate accessor methods for traversing the rule group" do
    User.should respond_to(:all)
    User.should respond_to(:old)
    User.should respond_to(:young)
    NewsStory.should respond_to(:all)
    NewsStory.should respond_to(:featured)
    NewsStory.should respond_to(:embargoed)
  end

  it "generate chained method on node traversal objects" do
    User.all.should respond_to(:old)
    User.old.should respond_to(:all)
  end


  it "rule each changed node" do
    a = User.new :age => 25
    b = User.new :age => 4
    lambda {finish_tx}.should change(User.all, :size).by(2)

    User.all.should include(a)
    User.all.should include(b)
    User.old.should include(a)
    User.old.should_not include(b)
    User.young.should include(b)
  end

  it "rule only instances of the given class (no side effects)" do
    User.new :age => 25
    User.new :age => 4
    lambda {new_tx}.should_not change(NewsStory.all, :size)

    NewsStory.new :featured => true, :publish_date => 2011
    lambda {new_tx}.should_not change(User.all, :size)
  end


  it "can chain rules" do
    a = NewsStory.new :publish_date => 2011, :featured => true
    b = NewsStory.new :publish_date => 2011, :featured => false
    c = NewsStory.new :publish_date => 2009, :featured => true
    finish_tx

    NewsStory.embargoed.should include(a)
    NewsStory.embargoed.should include(b)
    NewsStory.embargoed.should_not include(c)

    NewsStory.featured.should include(a)
    NewsStory.featured.should_not include(b)
    NewsStory.featured.should include(c)

    NewsStory.featured.embargoed.should include(a)
    NewsStory.featured.embargoed.should_not include(b)
    NewsStory.featured.embargoed.should_not include(c)

    NewsStory.all.featured.embargoed.should include(a)
    NewsStory.all.featured.embargoed.should_not include(b)
    NewsStory.all.featured.embargoed.should_not include(c)
  end


  it "remove nodes from rule group when a property change" do
    a = User.new :age => 25
    new_tx
    User.old.should include(a)

    # now, change age so that it does not belong to the group 'old'
    a[:age] = 8
    lambda {finish_tx}.should change(User.old, :size).by(-1)

    User.old.should_not include(a)
  end

  it "move rule group when property change" do
    a = User.new :age => 25
    new_tx
    User.old.should include(a)

    # now, change age so that it does not belong to the group 'old'
    a[:age] = 3
    lambda { finish_tx }.should change(User.young, :size).by(+1)

    User.old.should_not include(a)
    User.young.should include(a)
  end

  it "keep in the same rule group when property change" do
    a = User.new :age => 25
    new_tx

    # now, change age so that it does still belong to same group 'old'
    a[:age] = 20
    lambda { finish_tx }.should_not change(User.old, :size)

    User.old.should include(a)
    User.young.should_not include(a)
  end

  it "remove node from rule group when node is deleted" do
    a = User.new :age => 25
    new_tx

    # now, delete it
    lambda { a.del; finish_tx }.should change(User.all, :size).by(-1)
    User.all.should_not include(a)
    User.old.should_not include(a)
  end

end

