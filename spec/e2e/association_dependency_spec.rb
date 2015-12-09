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
  before(:each) do
    stub_const 'CALL_COUNT', called: 0

    stub_active_node_class('User') do
      property :name
      has_many :out, :tours, model_class: 'Tour', type: 'BOOKED_TOUR', dependent: :destroy_orphans
      has_many :out, :bands, model_class: 'Band', type: 'MANAGES_BAND', dependent: :destroy_orphans
      has_many :out, :comments, model_class: 'Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    stub_active_node_class('Tour') do
      property :name
      has_many :out, :routes, model_class: 'Route', type: 'HAS_ROUTE', dependent: :destroy
      has_many :out, :bands, model_class: 'Band', type: 'HAS_BAND'
      has_many :out, :comments, model_class: 'Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    stub_active_node_class('Route') do
      property :name
      has_one :in, :tour, model_class: 'Tour', origin: :routes
      has_many :out, :stops, model_class: 'Stop', type: 'STOPS_AT', dependent: :destroy_orphans
      has_many :out, :comments, model_class: 'Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    stub_active_node_class('Stop') do
      after_destroy lambda { CALL_COUNT[:called] += 1 }
      property :city
      has_many :in, :routes, model_class: 'Route', origin: :stops
      has_many :out, :comments, model_class: 'Comment', type: 'HAS_COMMENT', dependent: :destroy
      has_one :out, :poorly_modeled_thing, model_class: 'BadModel', type: 'HAS_TERRIBLE_MODEL', dependent: :delete
      has_many :out, :poorly_modeled_things, model_class: 'BadModel', type: 'HAS_TERRIBLE_MODELS', dependent: :delete
    end

    stub_active_node_class('Band') do
      property :name
      has_many :in, :tours, model_class: 'Tour', origin: :bands
      has_many :in, :users, model_class: 'User', origin: :bands
      has_many :out, :comments, model_class: 'Comment', type: 'HAS_COMMENT', dependent: :destroy
    end

    # There's no reason that we'd have this model responsible for destroying users.
    # We will use this to prove that the callbacks are not called when we delete the Stop that owns this
    stub_active_node_class('BadModel') do
      has_one :out, :user, model_class: 'User', type: 'HAS_A_USER', dependent: :destroy
      has_many :out, :users, model_class: 'User', type: 'HAS_USERS', dependent: :destroy
    end

    stub_active_node_class('Comment') do
      property :note
      # In the real world, there would be no reason to setup a dependency here since you'd never want to delete
      # the topic of a comment just because the topic is destroyed.
      # For the purpose of these tests, we're setting this to demonstrate that we are protected against loops.
      has_one :in, :topic, model_class: false, type: 'HAS_COMMENT', dependent: :destroy
    end
  end

  def routing_setup
    [Route, Stop].each(&:delete_all)
    CALL_COUNT[:called] = 0

    @route1 = Route.create(name: 'Primary Route')
    @route2 = Route.create(name: 'Secondary Route')
    @tour.routes << [@route1, @route2]


    # Pro Tip from Chris: No good metal shows happen in Manhattan.
    # Boston is iffy, too.
    city_names = %w(Philadelphia Brooklyn Manhattan Providence Boston)
    city_names.each_with_object({}) do |city_name, _stops|
      instance_variable_set("@#{city_name.downcase}", Stop.create(city: city_name))
    end

    # We always play Philly. Great DIY scene. If we can't get Brooklyn or Providence, we can do Manhattan and Boston.
    @route1.stops << [@philadelphia, @brooklyn, @providence]
    @route2.stops << [@philadelphia, @manhattan, @boston]
  end

  describe 'basic destruction' do
    let(:node) { User.create }

    context 'a node without relationships' do
      it 'quits out of the process without performing an expensive match' do
        expect_any_instance_of(Neo4j::ActiveNode::Query::QueryProxy).not_to receive(:unique_nodes_query)
        node.destroy
      end
    end

    context 'a node with relationshpis' do
      let(:band) { Band.create }
      before { node.bands << band }

      it 'continues as normal' do
        expect_any_instance_of(Neo4j::ActiveNode::Query::QueryProxy).to receive(:unique_nodes_query).and_call_original
        node.destroy
      end
    end
  end

  describe 'Grzesiek is booking a tour for his bands' do
    before(:each) do
      delete_db

      @user = User.create(name: 'Grzesiek')
      @tour = Tour.create(name: 'Absu and Woe')
      @user.tours << @tour
      @woe = Band.create(name: 'Woe')
      @absu = Band.create(name: 'Absu')

      [@woe, @absu].each do |band|
        @user.bands << band
        @tour.bands << band
      end
    end

    describe 'its primary route stops at every city except NYC and Boston, secondary route includes NYC/Boston' do
      before do
        routing_setup
      end

      context 'and he destroys a Stop with one of those weird BadModels' do
        before do
          bad = BadModel.create
          bad.user = @user
          bad.users << @user
          @boston.poorly_modeled_thing = bad
        end

        it 'deletes the BadModel in Cypher and does not kill his user account' do
          @boston.destroy
          expect(@user).to be_persisted
          expect(BadModel.count).to eq 0
        end
      end

      context 'the secondary route is destroyed' do
        before do
          expect(@philadelphia).to be_persisted

          expect(@manhattan).to be_persisted
          expect(@boston).to be_persisted
        end

        it 'destroys @manhattan and @boston but not @philadelphia' do
          expect { @route2.destroy }.not_to raise_error
          expect(@philadelphia).to be_persisted

          expect(@manhattan.exist?).to be false
          expect(@boston.exist?).to be false
        end

        it 'destroys the linked comment without everything blowing up' do
          @boston.comments << Comment.create(note: 'I really hope we do not have to play Boston.')
          expect(Comment.count).to eq 1
          expect { @route2.destroy }.not_to raise_error
          expect(Comment.count).to eq 0
        end
      end
    end

    context 'things are going terribly' do
      describe 'Grzesiek, in frustration, destroys his account' do
        it 'destroys all bands, tours, routes, stops, and comments' do
          expect { @user.destroy }.not_to raise_error
          expect(Tour.count).to eq 0
          expect(Route.count).to eq 0
          expect(Stop.count).to eq 0
          expect(Comment.count).to eq 0
          expect(Band.count).to eq 0
        end
      end

      context 'G recreates his account but bails on this tour' do
        before do
          routing_setup
        end

        it 'destroys all routes, stops, and comments' do
          expect { @tour.destroy }.not_to raise_error
          expect(Tour.count).to eq 0
          expect(Route.count).to eq 0
          expect(Stop.count).to eq 0
          expect(Comment.count).to eq 0
          expect(Band.count).to eq 2
        end
      end
    end
  end

  describe 'invalid options' do
    it 'raises an error when an invalid option is passed' do
      expect { Stop.has_many(:out, :fooz, dependent: :foo).to raise_error }
    end
  end
end
