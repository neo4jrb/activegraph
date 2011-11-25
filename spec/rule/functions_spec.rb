require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Rule::Functions::Count, :type => :transactional do


  context "rule :all, :functions => Count.new" do
    before(:all) do
      @clazz = create_node_mixin do
        property :age
      end
      @clazz.rule(:all, :functions => Neo4j::Rule::Functions::Count.new)
    end

    context "for a subclass" do
      before(:all) do

        class CountBaseClass
          include Neo4j::NodeMixin
          rule(:all, :functions => Count.new)
        end

        class CountSubClass < CountBaseClass
        end
      end

      it "should update counter for only subclass when a new subclass is created" do
        CountSubClass.new
        new_tx
        CountBaseClass.count(:all).should == 1
        CountSubClass.count(:all).should == 1

        CountBaseClass.new
        new_tx
        CountBaseClass.count(:all).should == 2
        CountSubClass.count(:all).should == 1

      end

      it "should update counter for both baseclass and subclass" do
        CountBaseClass.new
        new_tx
        CountSubClass.count(:all).should == 0
        CountBaseClass.count(:all).should == 1

        CountSubClass.new
        new_tx
        CountSubClass.count(:all).should == 1
        CountBaseClass.count(:all).should == 2
      end
    end


    context "when empty group" do
      it ".count(:all).should == 0" do
        @clazz.count(:all).should == 0
      end

      it ".count(:all).should == 1 when a new node has been created" do
        @clazz.new
        new_tx
        @clazz.count(:all).should == 1
      end
    end

    context "when one node" do
      before(:each) do
        @node = @clazz.new
        new_tx
      end

      it ".count(:all).should == 1" do
        @clazz.count(:all).should == 1
      end

      it "when deleted .count(:all).should == 0" do
        @clazz.count(:all).should == 1
        @node.del
        new_tx
        @clazz.count(:all).should == 0
      end

      it ".count(:all).should == 2 when another node is created" do
        @clazz.new
        new_tx
        @clazz.count(:all).should == 2
      end
    end
  end

  context "rule(:young, :functions => Count.new){ age < 30}" do
    before(:all) do
      @clazz = create_node_mixin do
        property :age
      end
      @clazz.rule(:young, :functions => Neo4j::Rule::Functions::Count.new) { age && age < 30 }
    end


    context "when empty group" do
      it ".count(:young).should == 0" do
        @clazz.count(:young).should == 0
      end

      it ".count(:young) should == 1 when a new young node has been created" do
        @clazz.new :age => 5
        new_tx
        @clazz.count(:young).should == 1
      end

      it ".count(:young) should == 0 when a NOT new young node has been created" do
        @clazz.new :age => 124
        new_tx
        @clazz.count(:young).should == 0
      end

      it ".young.count should == 0" do
        @clazz.young.count.should == 0
      end
    end

    context "when there is one NOT young node" do
      before(:each) do
        @node = @clazz.new :age => 421
        new_tx
      end

      it ".count(:young).should == 0" do
        @clazz.count(:young).should == 0
      end

      it "when deleted the .count(:young).should == 0" do
        @node.del
        new_tx
        @clazz.count(:young).should == 0
        @clazz.young.count.should == 0
      end

      it "when the node is changed into a young node (changed property), .count(:young).should == 1" do
        @node.age = 4
        new_tx
        @clazz.count(:young).should == 1
        @clazz.young.count.should == 1
      end

      it "when creating two young nodes, .count(:young).should == 2" do
        @clazz.new :age => 4
        @clazz.new :age => 5
        new_tx
        @clazz.count(:young).should == 2
        @clazz.young.count.should == 2
      end
    end

    context "when there is one young node" do
      before(:each) do
        @node = @clazz.new :age => 5
        new_tx
      end

      it ".count(:young).should == 1" do
        @clazz.count(:young).should == 1
        @clazz.young.count.should == 1
      end

      it "when deleted the .count(:young).should == 0" do
        @node.del
        new_tx
        @clazz.count(:young).should == 0
        @clazz.young.count.should == 0
      end
    end
  end

end

describe Neo4j::Rule::Functions::Sum, :type => :transactional do

  before(:all) do
    @clazz = create_node_mixin do
      property :age
    end
  end

  context "rule :all, :functions => Sum.new(:age)" do
    before(:all) do
      @clazz.rule :all, :functions => Neo4j::Rule::Functions::Sum.new(:age)
    end

    context "when empty group" do
      it "is zero" do
        @clazz.sum(:all, :age).should == 0
      end

      it "when creating a node it should add it's age" do
        @clazz.new :age => 42
        new_tx
        @clazz.sum(:all, :age).should == 42
      end

      it "when creating a node and it does not have a age property it should not change the sum" do
        @clazz.new
        new_tx
        @clazz.sum(:all, :age).should == 0
      end
    end

    context "when group has one node" do
      before(:each) do
        @node = @clazz.new :age => 10
        new_tx
      end

      it "when node is deleted it should subtract it's age from the sum" do
        @node.del
        new_tx
        @clazz.sum(:all, :age).should == 0
        @clazz.all.sum(:age).should == 0
      end

      it "when age property is changed it should change the sum" do
        @node[:age] = 20
        new_tx
        @clazz.sum(:all, :age).should == 20
      end

      it "when removing the age property it should remove the old age from the sum" do
        @node[:age] = nil
        new_tx
        @clazz.sum(:all, :age).should == 0
      end

      it "when creating two nodes it should add it's ages to the sum" do
        @node = @clazz.new :age => 100
        @node = @clazz.new :age => 1000
        new_tx
        @clazz.sum(:all, :age).should == 1110
      end
    end
  end

  context "rule :old, :functions => Sum.new(:age)" do
    before(:all) do
      @clazz.rule(:old, :functions => Neo4j::Rule::Functions::Sum.new(:age)) { age && age > 20 }
    end

    context "when empty group" do
      it "is zero" do
        @clazz.sum(:old, :age).should == 0
        @clazz.old.sum(:age).should == 0
      end

      it "when creating an old node it should add it's age" do
        @clazz.new :age => 42
        new_tx
        @clazz.sum(:old, :age).should == 42
        @clazz.old.sum(:age).should == 42
      end

      it "when creating a NOT old node it should NOT add it's age" do
        @clazz.new :age => 1
        new_tx
        @clazz.sum(:old, :age).should == 0
        @clazz.old.sum(:age).should == 0
      end

      it "when creating a node and it does not have an age property it should not change the sum" do
        @clazz.new
        new_tx
        @clazz.sum(:old, :age).should == 0
        @clazz.old.sum(:age).should == 0
      end
    end

    context "when group has one node" do
      before(:each) do
        @node = @clazz.new :age => 30
        new_tx
      end

      it "when node is deleted it should subtract it's age from the sum" do
        @node.del
        new_tx
        @clazz.sum(:old, :age).should == 0
        @clazz.old.sum(:age).should == 0
      end

      it "when age property is changed it should change the sum" do
        @node[:age] = 50
        new_tx
        @clazz.sum(:old, :age).should == 50
        @clazz.old.sum(:age).should == 50
      end

      it "when age property is changed so that it node is no longer in the old rule group it should subtract the age from the sum" do
        @node[:age] = 10
        new_tx
        @clazz.sum(:old, :age).should == 0
        @clazz.old.sum(:age).should == 0
      end

      it "when age property is changed so that it node is no longer it should still update the other rule group sum it is member of" do
        @node[:age] = 10
        new_tx
        @clazz.sum(:all, :age).should == 10
        @clazz.all.sum(:age).should == 10
      end

      it "when removing the age property it should remove the old age from the sum" do
        @node[:age] = nil
        new_tx
        @clazz.sum(:old, :age).should == 0
        @clazz.sum(:all, :age).should == 0
      end

      it "when creating two nodes it should add it's ages to the sum" do
        @node = @clazz.new :age => 100
        @node = @clazz.new :age => 1000
        new_tx
        @clazz.sum(:old, :age).should == 1130
        @clazz.old.sum(:age).should == 1130
        @clazz.sum(:all, :age).should == 1130
        @clazz.all.sum(:age).should == 1130
      end
    end

  end

end
