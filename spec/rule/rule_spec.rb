require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class Reader
  include Neo4j::NodeMixin
  property :age

  rule :all
  rule(:old) { age > 10 } # for testing evaluation in the context of a wrapped ruby object
  rule(:young, :triggers => :readers) { |node| node[:age] < 5 } # for testing using native java neo4j node
end

class MaleReader < Reader
  property :sex
end

class FastReader < Reader
  property :reading_speed

  rule(:all) { reading_speed > 1 }
end

class NewsStory
  include Neo4j::NodeMixin
  has_n :readers

  rule :all
  rule(:featured) { |node| node[:featured] == true }
  rule(:embargoed) { |node| node[:publish_date] > 2010 }
  # young readers for only young readers - find first person which is not young, if not found then the story has only young readers
  rule(:young_readers) { !readers.find { |user| !user.young? } }
end


describe "Neo4j::Node#rule", :type => :transactional do

  it "generate instance method: <rule_name>? for each rule" do
    young = Reader.new :age => 2
    young.should respond_to(:old?)
    young.should respond_to(:young?)
    young.should respond_to(:all?)
  end

  it "instance method <rule_name>?  return true if the rule evaluates to true" do
    young = Reader.new :age => 2
    old   = Reader.new :age => 20

    young.should be_young
    old.should be_old
  end

  it "generate accessor methods for traversing the rule group" do
    Reader.should respond_to(:all)
    Reader.should respond_to(:old)
    Reader.should respond_to(:young)
    NewsStory.should respond_to(:all)
    NewsStory.should respond_to(:featured)
    NewsStory.should respond_to(:embargoed)
  end

  it "generate chained method on node traversal objects" do
    Reader.all.should respond_to(:old)
    Reader.old.should respond_to(:all)
  end


  it "rule each changed node" do
    a = Reader.new :age => 25
    b = Reader.new :age => 4
    lambda { finish_tx }.should change(Reader.all, :size).by(2)

    Reader.all.should include(a)
    Reader.all.should include(b)
    Reader.old.should include(a)
    Reader.old.should_not include(b)
    Reader.young.should include(b)
  end

    #Run this test alone to reproduce the issue

  it "rule node created from concurrent threads" do
    Neo4j.threadlocal_ref_node = nil
    Reader.all.each(&:del)
    finish_tx
    Reader.all.size.should == 0
    threads = 50.times.collect do
      Thread.new do
        Neo4j.threadlocal_ref_node = nil
        tx = Neo4j::Transaction.new
        Reader.new(:age => 2)
        tx.success
        tx.finish
      end
     end
    threads.each(&:join)
    Reader.all.size.should == 50
  end

  it "rule only instances of the given class (no side effects)" do
    Reader.new :age => 25
    Reader.new :age => 4
    lambda { new_tx }.should_not change(NewsStory.all, :size)

    NewsStory.new :featured => true, :publish_date => 2011
    lambda { new_tx }.should_not change(Reader.all, :size)
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
    a = Reader.new :age => 25
    new_tx
    Reader.old.should include(a)

    # now, change age so that it does not belong to the group 'old'
    a[:age] = 8
    lambda { finish_tx }.should change(Reader.old, :size).by(-1)

    Reader.old.should_not include(a)
  end

  it "move rule group when property change" do
    a = Reader.new :age => 25
    new_tx
    Reader.old.should include(a)

    # now, change age so that it does not belong to the group 'old'
    a[:age] = 3
    lambda { finish_tx }.should change(Reader.young, :size).by(+1)

    Reader.old.should_not include(a)
    Reader.young.should include(a)
  end

  it "keep in the same rule group when property change" do
    a = Reader.new :age => 25
    new_tx

    # now, change age so that it does still belong to same group 'old'
    a[:age] = 20
    lambda { finish_tx }.should_not change(Reader.old, :size)

    Reader.old.should include(a)
    Reader.young.should_not include(a)
  end

  it "remove node from rule group when node is deleted" do
    a = Reader.new :age => 25
    new_tx

    # now, delete it
    lambda { a.del; finish_tx }.should change(Reader.all, :size).by(-1)
    Reader.all.should_not include(a)
    Reader.old.should_not include(a)
  end

  it "add nodes to rule group when a relationship is created" do
    user  = Reader.new :age => 2
    story = NewsStory.new :featured => true, :publish_date => 2009
    story.readers << user

    finish_tx

    NewsStory.young_readers.should include(story)
  end

  it "add nodes to rule group when a related node updates its property (trigger_rules)" do
    user  = Reader.new :age => 200
    story = NewsStory.new :featured => true, :publish_date => 2009
    story.readers << user

    new_tx
    NewsStory.young_readers.should_not include(story)

    user[:age] = 2
    finish_tx

    NewsStory.young_readers.should include(story)
  end


  it "add nodes to rule group when a related node is deleted (trigger_rules)" do
    user  = Reader.new :age => 2
    story = NewsStory.new :featured => true, :publish_date => 2009
    story.readers << user

    new_tx
    NewsStory.young_readers.should include(story)

    user.del
    Reader.new :age => 2

    finish_tx

    NewsStory.young_readers.should include(story)
  end


  context "when extended" do
    subject { @subject }

    before(:each) do
      new_tx
      @subject     = MaleReader.new
      @subject.age = 25
      finish_tx
    end

    it "should be included in Reader#old" do
      Reader.old.should include(subject)
    end

    it "should be included in MaleReader#old" do
      MaleReader.old.should include(subject)
    end

    it "should not be included after age change" do
      new_tx
      subject.age = 8
      finish_tx
      MaleReader.old.should_not include(subject)
      Reader.old.should_not include(subject)
    end
  end

  context "when extended and overwriting a rule" do
    subject { @subject }

    before(:each) do
      new_tx
      @subject               = FastReader.new
      @subject.age           = 25
      @subject.reading_speed = 0
      finish_tx
    end

    it "should be included in Reader#all" do
      Reader.all.should include(subject)
    end

    it "should not be included in FastReader#all" do
      FastReader.all.should_not include(subject)
    end

    context "after changing reading speed" do
      before(:each) { new_tx; subject.reading_speed = 2; finish_tx }

      it "should be included in Reader#all" do
        Reader.all.should include(subject)
      end

      it "should be included in FastReader#all" do
        FastReader.all.should include(subject)
      end
    end
  end
end
