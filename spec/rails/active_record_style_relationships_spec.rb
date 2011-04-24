require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j::Rails::Model Relationships" do

  class ModelRelationship1 < Neo4j::Rails::Relationship
    property :character
  end

  before(:each) do
    @actor_class = create_model(Neo4j::Model)
    @actor_class.property :name

    @movie_class = create_model(Neo4j::Model)
    @movie_class.property :title

    @actor_class.has_n(:acted_in).to(@movie_class).relationship(ModelRelationship1)
    @actor_class.has_one(:favorite).to(@movie_class)
    @movie_class.has_n(:actors).from(@movie_class, :acted_in)

    @actor_class.validates_associated(:acted_in)
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


    describe "delete_all on outgoing" do
      it "deletes all relationship" do
        @actor.acted_in.delete_all
        @actor.acted_in.size.should == 0
        Neo4j::Node.load(@movie_3.id).should == nil
      end
    end

    describe "destroy_all on outgoing" do
      it "destroy all relationship" do
        @actor.acted_in.destroy_all
        @actor.acted_in.size.should == 0
        Neo4j::Node.load(@movie_3.id).should == nil
      end
    end

    describe "delete on incoming rels" do
      it "can delete incoming" do
        @movie_2.actors.size.should == 2
        @movie_2.actors.delete(@actor)
        @movie_2.actors.size.should == 1
        @movie_2.actors.should include(@actor_2)
      end

      it "can find incoming" do
        rel = @movie_2.actors.find(@actor)
        rel.character = 'me'
        @movie_2.actors_rels.find(@actor).should == rel
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
  end

end