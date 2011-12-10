require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j::Rails::Model Relationships" do

  class ModelRelationship1 < Neo4j::Rails::Relationship
    property :character
  end

  before(:each) do
    @actor_class = create_model(Neo4j::Model)
    @actor_class.property :name
    @actor_class.property :description
    @actor_class.validates_length_of :description, :maximum => 10
    @movie_class = create_model(Neo4j::Model)
    @movie_class.property :title

    @actor_class.has_n(:acted_in).to(@movie_class).relationship(ModelRelationship1)
    @actor_class.has_one(:favorite).to(@movie_class)
    @movie_class.has_n(:actors).from(@actor_class, :acted_in)

    @actor_class.validates_associated(:acted_in)
  end

  context "traversal" do
    before(:each) do
      @n1 = Neo4j::Model.create
      @n2 = Neo4j::Model.create
      @n3 = Neo4j::Model.create
      @n1.outgoing(:foo) << @n2;  @n1.save!
      @n2.outgoing(:foo) << @n3;  @n2.save!
    end

    it "should still support outgoing traversals of depth > 1" do
      @n1.outgoing(:foo).depth(2).size.should == 2
      @n1.outgoing(:foo).depth(2).should include(@n2, @n3)
    end

    it "should still support incoming traversals of depth > 1" do
      @n3.incoming(:foo).depth(2).size.should == 2
      @n3.incoming(:foo).depth(2).should include(@n2, @n1)
    end

    it "should still support incoming traversals of depth == 1" do
      @n3.incoming(:foo).depth(1).size.should == 1
      @n3.incoming(:foo).depth(1).should include(@n2)
    end

  end

  context "has_one" do
    before(:each) do
      @actor = @actor_class.create
      @movie_1 = @movie_class.create :title => 'movie_1'
      @movie_2 = @movie_class.create :title => 'movie_2'
      @actor.favorite = @movie_1
      @actor.save
    end

    it "delete should only delete the relationship" do
      @actor.favorite.delete
      @actor.favorite.should == nil
      Neo4j::Node.find(@movie_1.id).should_not be_nil
      @actor.favorite_rel.should == nil
    end

    it "setting a has_one relationship will  delete previous relationship" do
      rel = @actor.favorite_rel
      @actor.favorite = @movie_2
      rel.should be_destroyed
      @actor.favorite.should == @movie_2
    end
  end

  context "has_n" do
    before(:each) do
      @actor = @actor_class.create
      @actor_2 = @actor_class.create

      @movie_1 = @movie_class.create :title => 'movie_1'
      @movie_2 = @movie_class.create :title => 'movie_2'
      @movie_3 = @movie_class.create :title => 'movie_3'

      @actor.acted_in << @movie_1 << @movie_2 << @movie_3
      @actor.save
      @movie_2.actors << @actor_2
      @movie_2.save
    end

    describe "used as nested form in active view" do
      it "#persisted? returns true if all relationships has been persisted" do
        @actor.acted_in.should be_persisted
      end

      it "#persisted? returns false if not all relationships has been persisted" do
        movie_4 = @movie_class.create :title => 'movie_4'
        @actor.acted_in << movie_4
        @actor.acted_in.should_not be_persisted
      end

    end

    describe "find nodes in relationship" do

      it "find all child nodes" do
        @actor.acted_in.find(:all).should_not be_nil
      end

      it "find first child node" do
        @actor.acted_in.find(:first).should_not be_nil
      end

      it "find a child node by node" do
        @actor.acted_in.find(@movie_1).should_not be_nil
      end

      it "find a child node by id" do
        @actor.acted_in.find(@movie_1.id).should_not be_nil
      end

      it "find a child node by delegate to Enumerable#find" do
        @actor.acted_in.find{|n| n.title == 'movie_1'}.should_not be_nil
      end
    end

    describe "find rels by node or id" do
      it "find all rels" do
        @actor.acted_in_rels.find(:all).should_not be_nil
      end

      it "find first rel" do
        @actor.acted_in_rels.find(:all).should_not be_nil
      end

      it "find rels for a node, by node" do
        @actor.acted_in_rels.find(@movie_1).should_not be_nil
      end

      it "find rels by id" do
        relid = @actor.acted_in_rels.find(@movie_1).id
        @actor.acted_in_rels.find(relid).should_not be_nil
      end

      it "find all rels for a node, by node" do
        @actor.acted_in_rels.find(:all, @movie_1).should be_kind_of(Enumerable)
      end

      it "find all rels for a node, by node id" do
        @actor.acted_in_rels.find(:all, @movie_1.id).should be_kind_of(Enumerable)
      end

      it "find first rels for a node, by node" do
        @actor.acted_in_rels.find(:first, @movie_1).should be_kind_of(Neo4j::Rails::Relationship)
      end

      it "find first rels for a node, by node id" do
        @actor.acted_in_rels.find(:first, @movie_1.id).should_not be_nil
      end

    end

    describe "connect outgoing nodes" do
      before(:each) do
        @movie_4 = @movie_class.create :title => 'movie_4'
        @ret = @actor.acted_in_rels.connect(@movie_4, :since => 2001)
      end

      it "creates a new relationship with the given properties" do
        @ret.should be_kind_of(ModelRelationship1)
        @ret[:since].should == 2001
      end

      it "connects the two nodes" do
        @actor.outgoing(@actor_class.acted_in).should include(@movie_4)
      end

      it "saves the new relationship with save is called" do
        @actor.save
        @actor._java_node.outgoing(@actor_class.acted_in).should include(@movie_4)
      end

      it "one can connect two nodes without having to specify properties on the relationship" do
        @movie_5 = @movie_class.create :title => 'movie_5'
        @actor.acted_in_rels.connect(@movie_5)
        @actor.outgoing(@actor_class.acted_in).should include(@movie_5)
      end
    end

    describe "build outgoing on rel" do
      before(:each) do
        @ret = @actor.acted_in_rels.build(:title => 'movie_4')
      end

      it "should allow to build a relationship with no properties" do
        rel = @actor.acted_in_rels.build
        rel.props.size.should == 1
      end

      it "create a new node but does not save it" do
        @actor.acted_in.size.should == 4
      end

      it "create a new node but does not save it" do
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should_not be_persisted
      end

      it "does not create a new relationship" do
        @actor.reload
        @actor.acted_in.size.should == 3
      end

      it "returns new node " do
        @ret.should be_kind_of(ModelRelationship1)
      end
    end

    describe "create outgoing on rel" do
      before(:each) do
        @ret = @actor.acted_in_rels.create(:title => 'movie_4')
      end

      it "create a new node and save it" do
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should be_persisted
        @actor.acted_in.size.should == 4
      end

      it "create a new relationship" do
        @actor.reload
        @actor.acted_in.size.should == 4
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should be_persisted
      end

      it "returns new node " do
        @ret.should be_kind_of(ModelRelationship1)
      end
    end

    describe "create! outgoing on rel" do
      before(:each) do
        @ret = @actor.acted_in_rels.create!(:title => 'movie_4')
      end

      it "create a new node and save it" do
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should be_persisted
        @actor.acted_in.size.should == 4
      end

      it "create a new relationship" do
        @actor.reload
        @actor.acted_in.size.should == 4
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should be_persisted
      end

      it "returns new node " do
        @ret.should be_kind_of(ModelRelationship1)
      end
    end

    describe "build outgoing" do
      before(:each) do
        @ret = @actor.acted_in.build(:title => 'movie_4')
      end

      it "create a node with no properties if none is given" do
        actor = @actor_class.create
        node =  actor.acted_in.build
        actor.acted_in.size.should == 1
        node.props.size.should == 1
        node.should_not be_persisted
      end

      it "create a new node but does not save it" do
        @actor.acted_in.size.should == 4
      end

      it "create a new node but does not save it" do
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should_not be_persisted
      end

      it "returns new node " do
        @ret.should be_kind_of(@movie_class) #ModelRelationship1
      end
    end

    describe "create outgoing" do
      before(:each) do
        @ret = @actor.acted_in.create(:title => 'movie_4')
      end

      it "create a new node and save it" do
        @actor.acted_in.size.should == 4
      end

      it "create a new node and save it" do
        @actor.acted_in.find{|x| x.title == 'movie_4'}.should be_persisted
      end

      it "returns new node " do
        @ret.should be_kind_of(@movie_class) #ModelRelationship1
      end

      it "persist the relationship" do
        @actor.reload
        @actor.acted_in.size.should == 4
      end

    end

    describe "create incoming" do
      before(:each) do
        @ret = @movie_1.actors.create(:name => 'actor_x')
      end

      it "create a new node and save it" do
        @movie_1.actors.size.should == 2
      end

      it "create a new node and save it" do
        @movie_1.actors.find{|x| x.name == 'actor_x'}.should be_persisted
      end

      it "returns new node " do
        @ret.should be_kind_of(Neo4j::Rails::Model) #ModelRelationship1
      end

    end

    describe "build incoming" do
      before(:each) do
        @ret = @movie_1.actors.build(:name => 'actor_x')
      end

      it "create a new node but does not save it" do
        @movie_1.actors.size.should == 2
      end

      it "create a new node but does not save it" do
        @movie_1.actors.find{|x| x.name == 'actor_x'}.should_not be_persisted
      end

      it "returns new node " do
        @ret.should be_kind_of(Neo4j::Rails::Model) # have node declare mapping the other way
      end

    end



    describe "delete_all on outgoing nodes" do
      it "deletes all relationship" do
        @actor.acted_in.delete_all
        @actor.acted_in.size.should == 0
        Neo4j::Node.load(@movie_3.id).should == nil
      end
    end

    describe "destroy_all on outgoing nodes" do
      it "destroy all relationship" do
        @actor.acted_in.destroy_all
        @actor.acted_in.size.should == 0
        Neo4j::Node.load(@movie_3.id).should == nil
      end
    end

    describe "delete_all on incoming nodes" do
      it "deletes all relationship" do
        @movie_2.actors.delete_all
        @movie_2.actors.size.should == 0
        Neo4j::Node.load(@actor.id).should == nil
      end
    end

    describe "destroy_all on incoming nodes" do
      it "destroy all relationship" do
        @movie_2.actors.destroy_all
        @movie_2.actors.size.should == 0
        Neo4j::Node.load(@actor.id).should == nil
      end
    end

    describe "delete_all on outgoing relationships" do
      it "deletes all relationship" do
        @actor.acted_in_rels.delete_all
        @actor.acted_in.size.should == 0
        @actor.acted_in_rels.size.should == 0
        Neo4j::Node.load(@movie_3.id).should_not == nil
      end
    end

    describe "destroy_all on outgoing relationships" do
      it "destroy all relationship" do
        @actor.acted_in_rels.destroy_all
        @actor.acted_in.size.should == 0
        @actor.acted_in_rels.size.should == 0
        Neo4j::Node.load(@movie_3.id).should_not == nil
      end
    end

    describe "delete_all on incoming nodes" do
      it "deletes all relationship" do
        @movie_2.actors_rels.delete_all
        @movie_2.actors_rels.size.should == 0
        Neo4j::Node.load(@actor.id).should_not == nil
      end
    end

    describe "destroy_all on incoming nodes" do
      it "destroy all relationship" do
        @movie_2.actors_rels.destroy_all
        @movie_2.actors_rels.size.should == 0
        Neo4j::Node.load(@actor.id).should_not == nil
      end
    end

    describe "delete on incoming rels" do
      it "can delete incoming" do
        @movie_2.actors.size.should == 2
        @movie_2.actors.delete(@actor)
        @movie_2.actors.size.should == 1
        @movie_2.actors.should include(@actor_2)
      end

      it "can find and delete incoming" do
        rel = @movie_2.actors_rels.find(@actor)
        rel.should be_kind_of(ModelRelationship1)
        rel.delete
        @movie_2.actors_rels.find(@actor).should be_nil
      end
    end

    describe "delete on outgoing rels" do
      it "Removes one from the collection" do
        @actor.acted_in.delete(@movie_2)
        @actor.acted_in.should_not include(@movie_2)
        @actor.acted_in.should include(@movie_1, @movie_3)
        @actor.acted_in.size.should == 2
      end

      it "Removes more objects from the collection." do
        @actor.acted_in.size.should == 3
        @actor.acted_in.delete(@movie_2, @movie_1, @movie_3)
        @actor.acted_in.should be_empty
      end

      it "does not destroy the objects" do
        ModelRelationship1.all.size.should == 3
        @actor.acted_in.delete(@movie_2, @movie_1, @movie_3)
        ModelRelationship1.all.size.should == 0
        [@movie_2, @movie_1, @movie_3].each { |n| Neo4j::Node.load(n.id).should_not be_nil }
      end
    end

    describe "validation" do
      it "Allows traversal when validation fails" do
        @actor.description = "abcdefghijk"
        @actor.save
        @actor.valid?.should be_false
        @actor.acted_in.delete(@movie_2)
        @actor.acted_in_rels.find(@movie_2).should be_nil
      end
    end
  end

end
