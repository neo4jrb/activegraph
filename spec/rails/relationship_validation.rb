require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe "Neo4j::Rails::Model#validates_associated" do
  before(:all) do
    @actor_class = create_model(Neo4j::Model, "Actor")
    @actor_class.property :name

    @movie_class = create_model(Neo4j::Model, "Movie")

    @role_class = create_rel_model
    @role_class.property :character

    @actor_class.has_n(:acted_in).relationship(@role_class)
    @actor_class.validates_associated(:acted_in)
  end

  describe "validation of relationships" do
    before(:all) do
      @role_class.validates_presence_of :character
      # a bit strange relationship, but we need to test depth 2 validation
      @movie_class.has_n(:stars).relationship(@role_class)
      @movie_class.validates_associated(:stars)
    end

    it "validation when invalid with depth 1" do
      actor = @actor_class.new
      movie = @movie_class.new
      actor.acted_in << movie
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
      actor.save.should be_true
      actor.should be_valid
    end

  end

  describe "validation of nodes" do
    before(:all) do
      @actor_class.validates_presence_of :name
    end

    # TODO
  end

  describe "update_attributes validation" do

    it "does not save invalid nested nodes" do
      pending
      params = {:member => {:name => 'Jack', :avatar_attributes => {:icon => 'smiling'}}}
      member = Member.create(params[:member])
      params = {:member => {:descriptions_attributes => [{:text => 'bla bla bla'}]}}
      member.update_attributes(params[:member]).should be_false
      member.reload
      member.descriptions.should be_empty
    end

  end

end