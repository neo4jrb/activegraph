require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j::NodeMixin#list :events", :type => :transactional do
  before(:all) do
    @clazz = create_node_mixin do
      has_list :events
    end
  end

  describe "not empty list" do
    before(:all) do
      new_tx
      @root = @clazz.new
    end

    before(:each) do
      new_tx
      @root.events[14243] = (@a = Neo4j::Node.new :name => 'a')
      @root.events[42]    = (@b = Neo4j::Node.new :name => 'b')
      @root.events[42]    = (@c = Neo4j::Node.new :name => 'c')
      @root.events[100]   = (@d = Neo4j::Node.new :name => 'd')
      new_tx
    end

    after(:each) do
      new_tx
      @root.events.each{|node| @root.events.remove(node)}
      finish_tx
    end

    describe "generated method 'events" do
      it "returns all nodes in this list" do
        @root.events.should include(@a, @b, @c, @d)
      end

      describe "[n]" do
        it "[n] returns the node with index n" do
          @root.events[14243].should == @a
          @root.events[100].should == @d
        end
      end

      describe "[n]=" do
        it "should increase the size when a node is added" do
          lambda { @root.events[51235] = Neo4j::Node.new }.should change(@root.events, :size).by(1)
        end

        it "can be accessed with the [n] operator" do
          @root.events[12345] = (node = Neo4j::Node.new)
          @root.events[12345].should == node
        end
      end

      describe "all(n)" do
        it "all(n) returns all the items with index n" do
          all = [*@root.events.all(42)]
          all.should include(@b, @c)
        end
      end

      describe "between(range)" do
        it "events.between(x,y) returns all nodes between x and y (Fixnum)" do
          @root.events.between(100..100).should include(@d)
          [*@root.events.between(100..100)].size.should == 1
          @root.events.between(2..99998).size.should == 4
          @root.events.between(2..99998).collect{|v| v}.should include(@a, @b, @c, @d)
        end
      end

      it "should delete the node from the list when the node is deleted" do
        @c.del
        new_tx
        @root.events.should include(@a, @b, @d)
        @root.events.should_not include(@c)
      end

      it "does not change size of the list when the node is deleted (!)" do
        new_tx
        lambda { @a.del }.should_not change(@root.events, :size)
        finish_tx
      end


      describe "remove" do
        it "removes the node from the lists " do
          @root.events.should include(@a)
          @root.events.remove(@a)
          @root.events.should_not include(@a)
        end

        it "decrease the size of the list by 1" do
          lambda { @root.events.remove(@a) }.should change(@root.events, :size).by(-1)
        end
      end
    end
  end

  describe "empty list" do
    before(:all) do
      new_tx
      @root = @clazz.new
      finish_tx
    end

    after(:each) do
      new_tx
      @root.events.each{|node| @root.events.remove(node)}
      finish_tx
    end

    describe "generated method 'events'" do
      it "should be empty" do
        @root.events.should be_empty
        @root.events.size.should == 0
      end

      describe "<<" do
        before(:each) do
          @root.events << (@a = Neo4j::Node.new)
          @root.events << (@b = Neo4j::Node.new)
          @root.events << (@c = Neo4j::Node.new)
          @root.events << (@d = Neo4j::Node.new)
        end

        it "returns all nodes in the order it was inserted" do
          [*@root.events].should == [@a, @b, @c, @d]
        end

        it "is inserted with the same index as the size of the list" do
          [*@root.events].should == [@a, @b, @c, @d]
          @root.events.size.should == 4
          @root.events[0].should == @a
          @root.events[1].should == @b
          @root.events[2].should == @c
          @root.events[3].should == @d
        end

        it "increase the size" do
          lambda { @root.events << Neo4j::Node.new }.should change(@root.events, :size).by(1)
        end

        it "#last returns the last item inserted" do
          @root.events.last.should == @d
        end

        it "#first returns the last item inserted" do
          @root.events.first.should == @a
        end

      end

      describe "first" do
        it "returns nil" do
          new_tx
          @root.events.each{|node| @root.events.remove(node)}
          finish_tx
          @root.events.first.should be_nil
        end
      end

      describe "last" do
        it "returns nil" do
          new_tx
          @root.events.each{|node| @root.events.remove(node)}
          finish_tx
          @root.events.last.should be_nil
        end
      end

    end
  end


end

