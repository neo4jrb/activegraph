require 'spec_helper'

describe "Neo4j::Rails::Model#validates_associated", :type => :integration do
  class RoleValidation < Neo4j::Rails::Relationship
    property :character
    validates_presence_of :character
  end

  class MovieValidation < Neo4j::Rails::Model
  end

  class ActorValidation < Neo4j::Rails::Model
    property :name
    has_n(:acted_in).to(MovieValidation).relationship(RoleValidation)
    has_one(:favorite).to(MovieValidation).relationship(RoleValidation)
    validates_associated(:acted_in)
    validates_associated(:favorite)
    accepts_nested_attributes_for :acted_in
  end

  class MovieValidation
    property :title
    property :year
    validates_presence_of :title
    has_n(:stars).relationship(RoleValidation)
    validates_associated(:stars)

    def to_s
      "Movie #{object_id} id: #{id} title: #{title} year: #{year}"
    end
  end

  describe "validation of has_one relationships" do

    it "validation when invalid with depth 1" do
      actor = ActorValidation.new
      movie = MovieValidation.new :title => 'matrix'
      actor.favorite = movie
      # missing validates_presence_of :character
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 1" do
      actor = ActorValidation.new
      movie = MovieValidation.new :title => 'matrix'
      actor.favorite = movie
      # set validates_presence_of :character
      actor.favorite_rel.character = "foo"
      actor.save.should be_true
    end
  end


  describe "validation of relationship in has_one nodes" do
    it "validation when invalid with depth 1" do
      actor = ActorValidation.new

      # missing validates_presence_of :title
      actor.favorite = MovieValidation.new
      actor.favorite_rel.character = "foo"

      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 1" do
      actor = ActorValidation.new
      # set missing validates_presence_of :title
      actor.favorite = MovieValidation.new(:title => 'matrix')
      actor.favorite_rel.character = "foo"
      actor.save.should be_true
    end

  end


  describe "validation of relationship for has_n relationships" do
    it "validation when invalid with depth 1" do
      actor = ActorValidation.new
      # missing set validates_presence_of :character
      actor.acted_in << MovieValidation.new(:title => 'matrix')
      actor.should_not be_valid
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 1" do
      actor = ActorValidation.new
      movie = MovieValidation.new(:title => 'matrix')
      actor.acted_in << movie
      # set validates_presence_of :character
      rel = actor.acted_in_rels.first
      rel.character = "micky mouse"
      actor.should be_valid
      actor.save.should be_true

      m = Neo4j::Node.load(movie.id)
      actor.should be_valid
    end


    it "does not save any associated nodes if one is invalid (atomic commit)" do
      actor = ActorValidation.new
      nbr_roles = RoleValidation.count
      nbr_actors = ActorValidation.count
      nbr_movies = MovieValidation.count

      # valid
      movie1 = MovieValidation.new :title => 'movie1'
      rel1 = RoleValidation.new(ActorValidation.acted_in, actor, movie1)
      rel1.character = "micky mouse"

      # not valid, missing character
      movie2 = MovieValidation.new :title => 'movie2'
      rel2 = RoleValidation.new(ActorValidation.acted_in, actor, movie2)

      # valid
      movie3 = MovieValidation.new :title => 'movie3'

      rel3 = RoleValidation.new(ActorValidation.acted_in, actor, movie3)
      rel3.character = "micky mouse"

      actor.save.should_not be_true
      actor.should_not be_valid

      rel1.should_not be_persisted
      rel2.should_not be_persisted

      RoleValidation.count.should == nbr_roles
      ActorValidation.count.should == nbr_actors
      MovieValidation.count.should == nbr_movies
    end


    it "validation when invalid with depth 2" do
      actor = ActorValidation.new
      movie = MovieValidation.new :title => 'matrix'

      # depth 1, valid
      actor.acted_in << movie
      role = actor.acted_in_rels.first
      role.character = 'micky mouse'

      # depth 2, invalid missing character
      star = ActorValidation.new
      movie.stars << star

      # then
      actor.should_not be_valid
      actor.save.should be_false
      actor.should_not be_valid
    end

    it "validation when valid with depth 2" do
      actor = ActorValidation.new
      movie = MovieValidation.new :title => 'matrix'
      # depth 1
      actor.acted_in << movie
      role = actor.acted_in_rels.first
      role.character = 'micky mouse'

      # depth 2
      star = ActorValidation.new
      movie.stars << star
      rel = movie.stars_rels.first
      rel.character = 'micky mouse'

      # then
      actor.should be_valid
      actor.save.should be_true
    end

  end

  describe "validation of nodes" do
    it "validation when invalid depth 1" do
      actor = ActorValidation.new
      movie = MovieValidation.new
      # missing title
      actor.acted_in << movie
      rel = actor.acted_in_rels.first
      rel.character = "micky mouse"

      actor.save.should be_false
    end

    it "validation when valid depth 1" do
      actor = ActorValidation.new
      movie = MovieValidation.new
      movie.title = "matrix"
      actor.acted_in << movie
      rel = actor.acted_in_rels.first
      rel.character = "micky mouse"

      actor.save.should be_true
    end

  end

  describe "update_attributes validation" do
    it "does save valid nested nodes" do
      # can't set relationship properties with update_attributes method
      params = {:name => 'Jack', :acted_in_attributes => [{:title => 'matrix'}]}
      actor = ActorValidation.new
      actor.update_attributes(params).should be_false
    end
  end

end