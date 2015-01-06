require 'spec_helper'

describe 'association dependent delete/destroy' do
  # In these tests, we mimic an event management system. It has a few requirements:
  #
  # -A User can have many Tours and Bands
  # -A Tour can have many Routes and Bands
  # -A Route must have exactly one Tour
  # -A Route can have many Stops
  # -A Stop can be part of many Routes and must have at least one
  # -A Band can be a part of many tours but must have at least one User
  # -Everything can be commented on. When an object is destroyed, all comments can be deleted in the database.
  module DependentSpec
    CALL_COUNT = {called: 0}

    class User
      include Neo4j::ActiveNode
      property :name
      has_many :out, :tours, model_class: 'DependentSpec::Tour', type: 'BOOKED_TOUR', dependent: :destroy_orphans
      has_many :out, :bands, model_class: 'DependentSpec::Band', type: 'MANAGES_BAND', dependent: :destroy_orphans
      has_many :out, :comments, model_class: 'DependentSpec::Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    class Tour
      include Neo4j::ActiveNode
      property :name
      has_many :out, :routes, model_class: 'DependentSpec::Route', type: 'HAS_ROUTE', dependent: :destroy
      has_many :out, :bands, model_class: 'DependentSpec::Band', type: 'HAS_BAND'
      has_many :out, :comments, model_class: 'DependentSpec::Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    class Route
      include Neo4j::ActiveNode
      property :name
      has_one :in,  :tour,  model_class: 'DependentSpec::Tour', origin: :routes
      has_many :out, :stops, model_class: 'DependentSpec::Stop', type: 'STOPS_AT', dependent: :destroy_orphans
      has_many :out, :comments, model_class: 'DependentSpec::Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    class Stop
      include Neo4j::ActiveNode
      after_destroy lambda { DependentSpec::CALL_COUNT[:called] += 1 }
      property :city
      has_many :in, :routes, model_class: 'DependentSpec::Route', origin: :stops
      has_many :out, :comments, model_class: 'DependentSpec::Comment', type: 'HAS_COMMENT', dependent: :destroy
      has_one :out, :poorly_modeled_thing, model_class: 'DependentSpec::BadModel', type: 'HAS_TERRIBLE_MODEL', dependent: :delete
      has_many :out, :poorly_modeled_things, model_class: 'DependentSpec::BadModel', type: 'HAS_TERRIBLE_MODELS', dependent: :delete
    end

    class Band
      include Neo4j::ActiveNode
      property :name
      has_many :in, :tours, model_class: 'DependentSpec::Tour', origin: :bands
      has_many :in, :users, model_class: 'DependentSpec::User', origin: :bands
      has_many :out, :comments, model_class: 'DependentSpec::Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    # There's no reason that we'd have this model responsible for destroying users.
    # We will use this to prove that the callbacks are not called when we delete the Stop that owns this
    class BadModel
      include Neo4j::ActiveNode
      has_one :out, :user, model_class: 'DependentSpec::User', type: 'HAS_A_USER', dependent: :destroy
      has_many :out, :users, model_class: 'DependentSpec::User', type: 'HAS_USERS', dependent: :destroy
    end

    class Comment
      include Neo4j::ActiveNode
      property :note
      # In the real world, there would be no reason to setup a dependency here since you'd never want to delete
      # the topic of a comment just because the topic is destroyed.
      # For the purpose of these tests, we're setting this to demonstrate that we are protected against loops.
      has_one :in, :topic, model_class: false, type: 'HAS_COMMENT', dependent: :destroy
    end
  end

  def initial_setup
    @user = DependentSpec::User.create(name: 'Grzesiek')
    @tour = DependentSpec::Tour.create(name: 'Absu and Woe')
    @user.tours << @tour
    @woe = DependentSpec::Band.create(name: 'Woe')
    @absu = DependentSpec::Band.create(name: 'Absu')

    [@woe, @absu].each do |band|
      @user.bands << band
      @tour.bands << band
    end
  end

  def routing_setup
    [DependentSpec::Route, DependentSpec::Stop].each(&:delete_all)
    DependentSpec::CALL_COUNT[:called] = 0

    @route1 = DependentSpec::Route.create(name: 'Primary Route')
    @route2 = DependentSpec::Route.create(name: 'Secondary Route')
    @tour.routes << [@route1, @route2]

    @philly = DependentSpec::Stop.create(city: 'Philadelphia')
    @brooklyn = DependentSpec::Stop.create(city: 'Brooklyn')
    @nyc = DependentSpec::Stop.create(city: 'Manhattan') # Pro Tip from Chris: No good metal shows happen in Manhattan.
    @providence = DependentSpec::Stop.create(city: 'Providence')
    @boston = DependentSpec::Stop.create(city: 'Boston') # Boston is iffy, too.

    # We always play Philly. Great DIY scene. If we can't get Brooklyn or Providence, we can do Manhattan and Boston.
    @route1.stops << [@philly, @brooklyn, @providence]
    @route2.stops << [@philly, @nyc, @boston]
  end

  describe 'Grzesiek is booking a tour for his bands' do
    before(:all) do
      initial_setup
    end

    describe 'its primary route stops at every city except NYC and Boston, secondary route includes NYC/Boston' do
      before do
        routing_setup
      end

      context 'and he destroys a Stop with one of those weird BadModels' do
        before do
          bad = DependentSpec::BadModel.create
          bad.user = @user
          bad.users << @user
          @boston.poorly_modeled_thing = bad
        end

        it 'deletes the BadModel in Cypher and does not kill his user account' do
          @boston.destroy
          expect(@user).to be_persisted
          expect(DependentSpec::BadModel.count).to eq 0
        end
      end

      context 'the secondary route is destroyed' do
        before do
          expect(@philly).to be_persisted
          [@nyc, @boston].each { |stop| expect(stop).to be_persisted }
        end

        it 'destroys @nyc and @boston but not @philly' do
          expect { @route2.destroy }.not_to raise_error
          expect(@philly).to be_persisted
          [@nyc, @boston].each { |stop| expect(stop).not_to be_persisted }
        end

        it 'destroys the linked comment without everything blowing up' do
          @boston.comments << DependentSpec::Comment.create(note: 'I really hope we do not have to play Boston.')
          expect(DependentSpec::Comment.count).to eq 1
          expect { @route2.destroy }.not_to raise_error
          expect(DependentSpec::Comment.count).to eq 0
        end
      end
    end

    context 'things are going terribly' do
      describe 'Grzesiek, in frustration, destroys his account' do
        it 'destroys all bands, tours, routes, stops, and comments' do
          expect { @user.destroy }.not_to raise_error
          expect(DependentSpec::Tour.count).to eq 0
          expect(DependentSpec::Route.count).to eq 0
          expect(DependentSpec::Stop.count).to eq 0
          expect(DependentSpec::Comment.count).to eq 0
          expect(DependentSpec::Band.count).to eq 0
        end
      end

      context 'G recreates his account but bails on this tour' do
        before do
          initial_setup
          routing_setup
        end

        it 'destroys all routes, stops, and comments' do
          expect { @tour.destroy }.not_to raise_error
          expect(DependentSpec::Tour.count).to eq 0
          expect(DependentSpec::Route.count).to eq 0
          expect(DependentSpec::Stop.count).to eq 0
          expect(DependentSpec::Comment.count).to eq 0
          expect(DependentSpec::Band.count).to eq 2
        end
      end
    end
  end
end
