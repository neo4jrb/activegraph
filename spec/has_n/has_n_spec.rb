require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class Person
  include Neo4j::NodeMixin
  property :name
  property :city

  has_n :friends
  has_one :address
  has_n(:employed_by).from(:employees)
  index :name
end

describe Neo4j::NodeMixin, "#has_n", :type => :transactional do

  before(:all) do
    @class = create_node_mixin do
      has_n :friends
    end
  end

  describe "generated class methods" do
    it "has_n :baaz will generate class method baaz returning 'baaz" do
      clazz = create_node_mixin do
        has_n :baaz
      end

      clazz.baaz.should == "baaz"
    end

    it "has_n(:baaz).to(Foo) will generate class method baaz returning 'Foo#baaz" do
      foo = create_node_mixin
      clazz = create_node_mixin do
        has_n(:baaz).to(foo)
      end

      clazz.baaz.should == "#{clazz}#baaz"
    end

    it "has_n(:foo).to(illegal arg) should raise" do
      clazz = create_node_mixin
      lambda{clazz.has_n(:baaz).to("ILLEGAL")}.should raise_exception
    end

    it "has_n(:foobar).from(Foo, :baaz) will generate class method foobar returning 'Foo#baaz" do
      clazz = create_node_mixin

      foo = create_node_mixin do
        has_n(:baaz).to(clazz)
      end

      foo.baaz.should == "#{foo}#baaz"
      clazz.has_n(:foobar).from(foo, :baaz)
      clazz.foobar.should == "#{foo}#baaz"
    end
  end

  
  context "unspecified outgoing relationship, e.g. has_n(:friends)" do
    before(:all) do
      new_tx
      @node = @class.new
      @a = Neo4j::Node.new(:item=>'a')
      @b = Neo4j::Node.new(:item=>'b')
      @c = Neo4j::Node.new(:item=>'c')
      @node.friends << @a << @b << @c
      finish_tx
    end

    it "#[] returns the n'th item" do
      @node.friends.should include(@a,@b,@c)
      array = [@node.friends[0], @node.friends[1], @node.friends[2]]
      array.should include(@a,@b,@c)
    end
  end


  context "specified relationship: has_n(:friends).relationship(Role)" do
    before(:all) do
      @role_class    = create_rel_mixin
      @company_class = create_node_mixin
      @company_class.has_n(:employees).relationship(@role_class)
    end

    context "generated 'employees' method" do
      it "<< create Role Relationships" do
        company = @company_class.new
        company.employees << Neo4j::Node.new
        # then
        company.employees_rels.first.class.should == @role_class
      end
    end

    context "generated 'friends_rels' method" do
      before(:each) do
        @p1 = @class.new
        @p2 = Neo4j::Node.new
        @p3 = Neo4j::Node.new
        @p4 = Neo4j::Node.new
        @r2 = Neo4j::Relationship.new(:friends, @p1, @p2)
        @r3 = Neo4j::Relationship.new(:friends, @p1, @p3)
        Neo4j::Relationship.new(:knows, @p1, @p4) # should not be returned, wrong type
        Neo4j::Relationship.new(:friends, Neo4j::Node.new, @p1) # should not be returned, incoming
      end

      it "returns the outgoing relationships of type 'friends'" do
        @p1.friends_rels.size.should == 2
        @p1.friends_rels.should include(@r2, @r3)
      end

      it "returned object respond to #to_other(node)" do
        @p1.friends_rels.should respond_to(:to_other)
      end

      context "#to_other(other_node)" do
        it "returns only nodes that are connected to the other_node" do
          @p1.friends_rels.to_other(@p2).size.should == 1
          @p1.friends_rels.to_other(@p2).should include(@r2)
          @p1.friends_rels.to_other(@p3).size.should == 1
          @p1.friends_rels.to_other(@p3).should include(@r3)
          @p1.friends_rels.to_other(@p4).should be_empty
        end

        it "#to_other(other_node).del can be used to delete all relationships between two nodes" do
          # when
          @p1.friends_rels.to_other(@p2).del

          # then
          @p1.friends.should_not include(@p2)
          @p1.friends.should include(@p3)
          new_tx
          @p2.should exist
        end
      end
    end


    context "generated 'friends' method" do
      context "when adding one Neo4j::Node  'from.friends << Neo4j::Node.new'" do
        before(:each) do
          @from = @class.new
          @to   = Neo4j::Node.new
          @from.friends << @to
        end

        it "creates a relationship of type 'friends' between node from and to" do
          @from.outgoing(:friends).first.should == @to
        end

        it "from.friends.first == to" do
          @from.friends.first.should == @to
        end
      end

      context "when adding ruby class including Neo4j::NodeMixin: a.friends << b" do
        before(:each) do
          @a = @class.new
          @b = @class.new
          @a.friends << @b
        end

        it "from.friends.first == to (should load the correct Ruby class)" do
          @a.friends.first.class.should == @b.class
        end
      end


      context "when adding several nodes: from.friends << to1 << to2" do
        before(:each) do
          @from = @class.new
          @to1  = Neo4j::Node.new
          @to2  = Neo4j::Node.new
          @from.friends << @to1 << @to2
        end

        it "from.friends should include the to1 and to2 nodes" do
          @from.friends.should include(@to1, @to2)
        end
      end

    end

  end

  context "specified outgoing relationship: has_n(:friends).to(OtherClass)" do
    context "generated 'friends' method" do
      before(:all) do
        @class = create_node_mixin {}
        @class.has_n(:friends).to(@class)
      end

      context "when adding: from.friends << to" do
        before(:each) do
          @from = @class.new
          @to   = Neo4j::Node.new
          @from.friends << @to
        end

        it "creates a relationship of type 'class#friends' between node from and to" do
          @from.outgoing("#{@class}#friends").first.should == @to
        end

        it "friends returns all outgoing relationships of type 'class#friends'" do
          Neo4j::Relationship.new("#{@class}#friends", @to, Neo4j::Node.new) # incoming
          Neo4j::Relationship.new("friends", @from, @to) # wrong type
          @from.friends.should include(@to)
          @from.friends.size.should == 1
        end
      end
    end
  end


  context "unspecified incoming relationship: has_n(:known_by).from(:friends)" do
    before(:all) do
      @class = create_node_mixin do
        has_n(:known_by).from(:friends)
      end
    end

    context "generated 'known_by_rels' method" do
      before(:each) do
        @p1 = @class.new
        @p2 = Neo4j::Node.new
        @p3 = Neo4j::Node.new
        @p4 = Neo4j::Node.new
        # create incoming relationships to p1
        @r2 = Neo4j::Relationship.new(:friends, @p2, @p1)
        @r3 = Neo4j::Relationship.new(:friends, @p3, @p1)
        Neo4j::Relationship.new(:knows, @p4, @p1) # should not be returned, wrong type
        Neo4j::Relationship.new(:friends, @p1, Neo4j::Node.new) # should not be returned, incoming
      end

      it "returns the incoming relationships of type 'friends'" do
        @p1.known_by_rels.size.should == 2
        @p1.known_by_rels.should include(@r2, @r3)
      end

      it "returned object respond to #to_other(node)" do
        @p1.known_by_rels.should respond_to(:to_other)
      end

      context "#to_other(other_node)" do
        it "returns only nodes that are connected to the other_node" do
          @p1.known_by_rels.to_other(@p2).size.should == 1
          @p1.known_by_rels.to_other(@p2).should include(@r2)
          @p1.known_by_rels.to_other(@p3).size.should == 1
          @p1.known_by_rels.to_other(@p3).should include(@r3)
          @p1.known_by_rels.to_other(@p4).should be_empty
        end

        it "#to_other(other_node).del can be used to delete all relationships between two nodes" do
          # when
          @p1.known_by_rels.to_other(@p2).del

          # then
          @p1.known_by.should_not include(@p2)
          @p1.known_by.should include(@p3)
          new_tx
          @p2.should exist # should only delete the relationship and not the node
        end
      end
    end

  end

  context "specified incoming relationship: has_n(:known_by).from(OtherClass, :friends)" do

    context "specified relationship: OtherClass.has_n(:friends).to(OtherClass).relationship(Role)" do
      before(:all) do
        @role_class  = create_rel_mixin
        @clazz       = create_node_mixin
        @other_class = create_node_mixin
        @other_class.has_n(:friends).to(@other_class).relationship(@role_class)
        @clazz.has_n(:known_by).from(@other_class, :friends)
      end

      context "generated 'known_by' method" do
        it "<< create Role Relationships between given nodes" do
          node = @clazz.new
          node.known_by << @other_class.new
          # then
          node.known_by_rels.first.class.should == @role_class
        end
      end
    end


    context "generated 'known_by' method" do
      before(:all) do
        @other_class = create_node_mixin "OtherClass"
        @class       = create_node_mixin "ThisClass"
        @other_class.has_n(:friends).to(@class)
        @class.has_n(:known_by).from(@other_class, :friends)
      end

      context "when adding: from.known_by << to" do
        before(:each) do
          @from = @class.new
          @to   = @other_class.new
          @from.known_by << @to
        end

        it "creates an incoming relationship of type 'class#friends" do
          @from.rel?("#{@other_class}#friends", :incoming).should be_true
        end

        it "known_by returns all incoming relationship of type 'class#friends'" do
          @from.known_by.first.should == @to
        end
      end
    end
  end

end
