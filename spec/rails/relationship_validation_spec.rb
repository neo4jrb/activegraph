require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j::Rails::Model#validates_associated" do
  before(:each) do
    @actor_class = create_model(Neo4j::Model)
    @actor_class.property :name

    @movie_class = create_model(Neo4j::Model)
    @movie_class.property :title

    @role_class = create_rel_model
    @role_class.property :character

    @actor_class.has_n(:acted_in).to(@movie_class).relationship(@role_class)
    @actor_class.has_one(:favorite).to(@movie_class).relationship(@role_class)

    @actor_class.validates_associated(:acted_in)
  end

  describe "validation of has_one relationships" do
    before(:each) do
      @role_class.validates_presence_of :character
      @actor_class.validates_associated(:favorite)
    end

    it "validation when invalid with depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      actor.favorite = movie
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      actor.favorite = movie
      actor.favorite_rel.character = "foo"
      actor.save.should be_true
    end

  end

  describe "validation of has_one nodes" do
    before(:each) do
      @actor_class.validates_associated(:favorite)
      @movie_class.validates_presence_of :title
    end

    it "validation when invalid with depth 1" do
      actor = @actor_class.new
      actor.favorite = @movie_class.new
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new(:title => 'matrix')
      actor.favorite = movie
      actor.favorite_rel.character = "foo"
      actor.save.should be_true
    end

  end


  describe "validation of has_n relationships" do
    before(:each) do
      @role_class.validates_presence_of :character
      # a bit strange relationship, but we need to test depth 2 validation
      @movie_class.has_n(:stars).relationship(@role_class)
      @movie_class.validates_associated(:stars)
      @actor_class.validates_associated(:acted_in)
    end

    it "validation when invalid with depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      actor.acted_in << movie
      actor.should_not be_valid
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      actor.acted_in << movie
      rel = actor.acted_in_rels.first
      rel.character = "micky mouse"
      actor.should be_valid
      actor.save.should be_true
      actor.valid?
      actor.should be_valid
    end


    it "does not save any associated nodes if one is invalid (atomic commit)" do
      @actor_class.has_n(:acted_in).relationship(@role_class)
      actor = @actor_class.new
      nbr_roles = @role_class.count
      nbr_actors = @actor_class.count
      nbr_movies = @movie_class.count

      # valid
      movie1 = @movie_class.new :name => 'movie1'
      rel1 = @role_class.new(@actor_class.acted_in, actor, movie1)
      rel1.character = "micky mouse"

      # not valid, missing character
      movie2 = @movie_class.new :name => 'movie2'
      rel2 = @role_class.new(@actor_class.acted_in, actor, movie2)

      # valid
      movie3 = @movie_class.new :name => 'movie3'
      rel3 = @role_class.new(@actor_class.acted_in, actor, movie3)
      rel3.character = "micky mouse"

      actor.save.should_not be_true
      actor.should_not be_valid

      rel1.should_not be_persisted
      rel2.should_not be_persisted

      @role_class.count.should == nbr_roles
      @actor_class.count.should == nbr_actors
      @movie_class.count.should == nbr_movies
    end


    it "validation when invalid with depth 2" do
      actor = @actor_class.new
      movie = @movie_class.new
      # depth 1
      actor.acted_in << movie
      role = actor.acted_in_rels.first
      role.character = 'micky mouse'

      # depth 2
      star = @actor_class.new
      movie.stars << star

      # then
      actor.should_not be_valid
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 2" do
      actor = @actor_class.new
      movie = @movie_class.new
      # depth 1
      actor.acted_in << movie
      role = actor.acted_in_rels.first
      role.character = 'micky mouse'

      # depth 2
      star = @actor_class.new
      movie.stars << star
      rel = movie.stars_rels.first
      rel.character = 'micky mouse'

      # then
      actor.should be_valid
      actor.save.should be_true
    end

  end

  describe "validation of nodes" do
    before(:each) do
      @movie_class.validates_presence_of :title
    end

    it "validation when invalid depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      actor.acted_in << movie

      actor.save.should be_false
    end

    it "validation when valid depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      movie.title = "matrix"
      actor.acted_in << movie

      actor.save.should be_true
    end

  end

  describe "update_attributes validation" do
    before(:each) do
      @movie_class.property :year
      @actor_class.accepts_nested_attributes_for :acted_in
      @movie_class.validates_presence_of :title
      @actor_class.validates_associated(:acted_in)
    end

    it "does not save invalid nested nodes" do
      params = {:name => 'Jack', :acted_in_attributes => {:year => '2001'}}
      actor = @actor_class.new
      actor.update_attributes(params)
      actor.acted_in.size.should == 1
      actor.save.should be_false
      @actor_class.find(actor.id).should be_nil
    end

    it "does save valid nested nodes" do
      params = {:name => 'Jack', :acted_in_attributes => [{:title => 'matrix'}]}
      actor = @actor_class.new
      actor.update_attributes(params).should be_true
      actor.acted_in.size.should == 1
      actor.acted_in.first.title.should == 'matrix'
      actor = @actor_class.find(actor.id)
      actor.acted_in.size.should == 1
      actor.acted_in.first.title.should == 'matrix'
    end

  end

end