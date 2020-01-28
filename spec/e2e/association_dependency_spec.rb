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
      has_many :out, :comments, model_class: 'Comment', type: 'HAS_COMMENT', dependent: :delete_orphans
      has_one :out, :poorly_modeled_thing, model_class: 'BadModel', type: 'HAS_TERRIBLE_MODEL', dependent: :delete
      has_many :out, :poorly_modeled_things, model_class: 'BadModel', type: 'HAS_TERRIBLE_MODELS', dependent: :delete
      has_many :out, :things, rel_class: 'MyRelClass', dependent: :destroy
      has_many :out, :things_2, rel_class: 'MyRelClass2', dependent: :destroy_orphans
      has_many :out, :things_3, rel_class: 'MyRelClass3', dependent: :delete
      has_many :out, :things_4, rel_class: 'MyRelClass4', dependent: :delete_orphans
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
      has_many :in, :stops, rel_class: 'MyRelClass', dependent: :destroy
      has_many :in, :stops_2, rel_class: 'MyRelClass2'
      has_many :in, :stops_3, rel_class: 'MyRelClass3'
      has_many :in, :stops_4, rel_class: 'MyRelClass4'
    end

    stub_active_node_class('Comment') do
      property :note
      # In the real world, there would be no reason to setup a dependency here since you'd never want to delete
      # the topic of a comment just because the comment is destroyed.
      # For the purpose of these tests, we're setting this to demonstrate that we are protected against loops.
      has_one :in, :topic, model_class: false, type: 'HAS_COMMENT', dependent: :destroy
    end

    stub_active_rel_class('MyRelClass') do
      from_class :Stop
      to_class :BadModel
      type 'rel_class_type'
    end

    stub_active_rel_class('MyRelClass2') do
      from_class :Stop
      to_class :BadModel
      type 'rel_class_type_2'
    end

    stub_active_rel_class('MyRelClass3') do
      from_class :Stop
      to_class :BadModel
      type 'rel_class_type_3'
    end

    stub_active_rel_class('MyRelClass4') do
      from_class :Stop
      to_class :BadModel
      type 'rel_class_type_4'
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

    context 'a node with relationships' do
      let(:band) { Band.create }
      before { node.bands << band }

      it 'continues as normal' do
        expect_any_instance_of(Neo4j::ActiveNode::Query::QueryProxy).to receive(:unique_nodes_query).and_call_original
        node.destroy
      end
    end

    context 'delete relationships' do
      context 'dependent destroy_orphans' do
        let(:orphan_band) { Band.create }
        let(:non_orphan_band) { Band.create }
        let(:other_band) { Band.create }
        let(:user_2) { User.create(bands: [non_orphan_band]) }
        before do
          node.bands = [orphan_band, non_orphan_band]
          user_2
        end

        it 'deletes only orphans' do
          node.bands = [other_band]
          expect{Band.find(orphan_band.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{Band.find(non_orphan_band.id)}.not_to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end

      context 'dependent destroy' do
        let(:comment) { Comment.create }
        let(:route) { Route.create(comments: [comment]) }
        let(:tour) { Tour.create(routes: [route]) }
        let(:route_2) { Route.create }
        it 'cascades dependent destroy' do
          tour.routes = [route_2]
          expect{Route.find(route.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{Comment.find(comment.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end

      context 'dependent delete' do
        let(:bad_model) { BadModel.create }
        let(:bad_model_2) { BadModel.create }
        let(:stop) { Stop.create(poorly_modeled_things: [bad_model]) }
        let(:stop_2) { Stop.create(poorly_modeled_things: [bad_model]) }
        it 'deletes dependent model node without cascade' do
          stop.poorly_modeled_things = [bad_model_2]
          expect{BadModel.find(bad_model.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{Stop.find(stop_2.id)}.not_to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end

      context 'dependent delete_orphans' do
        let(:comment_1) { Comment.create }
        let(:comment_2) { Comment.create }
        let(:comment_3) { Comment.create }
        let(:stop) { Stop.create(comments: [comment_1, comment_2]) }
        let!(:stop_2) { Stop.create(comments: [comment_2]) }
        it 'deletes only orphans' do
          stop.comments = [comment_3]
          expect{Comment.find(comment_1.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{Comment.find(comment_2.id)}.not_to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end
    end

    context 'destroy ActiveRel relationship' do
      context 'dependent destroy' do
        let(:bad_model) { BadModel.create }
        let(:city) { Stop.create(city: 'AMB') }
        let(:rel) { MyRelClass.create(from_node: city, to_node: bad_model) }

        it 'destroys the BadModel and Stop on deletion of ActiveRel' do
          rel.destroy
          expect{Stop.find(city.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{BadModel.find(bad_model.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end

      context 'dependent destroy orphans' do
        let(:bad_model_1) { BadModel.create }
        let(:city_1) { Stop.create(city: 'AMB') }
        let(:bad_model_2) { BadModel.create }
        let(:city_2) { Stop.create(city: 'UNR') }
        let(:rel_1) { MyRelClass2.create(from_node: city_1, to_node: bad_model_1) }
        let!(:rel_2) { MyRelClass2.create(from_node: city_1, to_node: bad_model_2) }
        let!(:rel_3) { MyRelClass2.create(from_node: city_2, to_node: bad_model_2) }
        it 'deletes only orphans' do
          rel_1.destroy
          expect{BadModel.find(bad_model_1.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{BadModel.find(bad_model_2.id)}.not_to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end

      context 'dependent delete' do
        let(:bad_model) { BadModel.create }
        let(:city) { Stop.create(city: 'AMB') }
        let(:rel) { MyRelClass3.create(from_node: city, to_node: bad_model) }
        it 'deletes relationship object' do
          rel.destroy
          expect{BadModel.find(bad_model.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
      end

      context 'dependent delete orphans' do
        let(:bad_model_1) { BadModel.create }
        let(:city_1) { Stop.create(city: 'AMB') }
        let(:bad_model_2) { BadModel.create }
        let(:city_2) { Stop.create(city: 'UNR') }
        let(:rel_1) { MyRelClass4.create(from_node: city_1, to_node: bad_model_1) }
        let!(:rel_2) { MyRelClass4.create(from_node: city_1, to_node: bad_model_2) }
        let!(:rel_3) { MyRelClass4.create(from_node: city_2, to_node: bad_model_2) }
        it 'deletes only orphans' do
          rel_1.destroy
          expect{BadModel.find(bad_model_1.id)}.to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
          expect{BadModel.find(bad_model_2.id)}.not_to raise_error Neo4j::ActiveNode::Labels::RecordNotFound
        end
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

      context 'we destroy stops, some of which have shared comments' do
        before do
          @philly_comment = Comment.create(note: "I'm looking forward to some of that brotherly love.")
          @man_philly_comment = Comment.create(note: 'Manhattan is better than Philly.')

          @philadelphia.comments << @philly_comment
          @philadelphia.comments << @man_philly_comment
          @manhattan.comments << @man_philly_comment
        end

        it 'only deletes orphan comments, not those associated with another city' do
          expect { @boston.destroy }.not_to raise_error

          expect(@philly_comment).to be_persisted
          expect(@man_philly_comment).to be_persisted

          @philadelphia.destroy

          expect(@philly_comment).not_to exist
          expect(@man_philly_comment).to exist

          @manhattan.destroy

          expect(@man_philly_comment).not_to exist
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
