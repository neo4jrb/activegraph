require 'spec_helper'

describe 'association dependent delete/destroy' do
  module DependentSpec
    CALL_COUNT = {called: 0}

    class Route
      include Neo4j::ActiveNode
      property :name
      property :call_count, type: Integer

      has_many :out, :stops, model_class: 'DependentSpec::Stop', type: 'STOPS_AT'
    end

    class Stop
      include Neo4j::ActiveNode
      after_destroy lambda { DependentSpec::CALL_COUNT[:called] += 1 }
      property :city
      has_many :in, :routes, model_class: 'DependentSpec::Route', origin: :stops
    end

    class << self
      def setup_callback(dependent_type)
        DependentSpec::Route.has_many :out, :stops,  model_class: 'DependentSpec::Stop', type: 'STOPS_AT', dependent: dependent_type
      end

      def setup_looping_callback(dependent_type)
        DependentSpec::Stop.has_many :in, :routes,  model_class: 'DependentSpec::Route', origin: :stops, dependent: dependent_type
      end
    end
  end

  before do
    DependentSpec::CALL_COUNT[:called] = 0
    @route1 = DependentSpec::Route.create(name: 'Route 1')
    @route2 = DependentSpec::Route.create(name: 'Route 2')
    @philly = DependentSpec::Stop.create(city: 'Philadelphia')
    @boston = DependentSpec::Stop.create(city: 'Boston')
    @route1.stops << @philly
    @route1.stops << @boston
    @route2.stops << @boston
  end

  describe 'dependent: :delete' do
    before do
      DependentSpec::Route.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:delete)
      @route1.reload
    end

    it 'deletes all association records from within Cypher' do
      DependentSpec::Route.before_destroy.clear
      [@philly, @boston].each { |l| expect(l).to be_persisted }
      @route1.destroy
      [@philly, @boston].each { |l| expect(l).not_to be_persisted }
      expect(DependentSpec::CALL_COUNT[:called]).to eq 0
    end
  end


  describe 'dependent: :delete_orphans' do
    before do
      DependentSpec::Route.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:delete_orphans)
      @route1.reload
    end

    it 'deletes all associated records that do not have other relationships of the same type from Cypher' do
      [@philly, @boston].each { |l| expect(l).to be_persisted }
      @route1.destroy
      expect(@philly).not_to be_persisted
      expect(@boston).to be_persisted
      expect(DependentSpec::CALL_COUNT[:called]).to eq 0
    end
  end

  describe 'dependent: :destroy' do
    before do
      DependentSpec::Route.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:destroy)
      @route1.reload
    end

    it 'destroys all associated records from Ruby' do
      DependentSpec::Route.before_destroy.clear
      [@philly, @boston].each { |l| expect(l).to be_persisted }
      @route1.destroy
      [@philly, @boston].each { |l| expect(l).not_to be_persisted }
      expect(DependentSpec::CALL_COUNT[:called]).to eq 2
    end
  end

  describe 'dependent :destroy_orphans' do
    before do
      DependentSpec::Route.reset_callbacks(:destroy)
      DependentSpec.setup_callback(:destroy_orphans)
      @route1.reload
    end

    it 'destroys all associated records that do not have other relationships of the same type from Ruby' do
      [@philly, @boston].each { |l| expect(l).to be_persisted }
      @route1.destroy
      expect(@philly).not_to be_persisted
      expect(@boston).to be_persisted
      expect(DependentSpec::CALL_COUNT[:called]).to eq 1
    end
  end

  describe 'nested dependencies' do
    module DependentSpec
      class Stop
        has_many :out, :bands, model_class: 'DependentSpec::Band', dependent: :destroy_orphans
      end

      class Route
        has_many :in, :bands, model_class: 'DependentSpec::Band', origin: :routes
      end

      class Band
        include Neo4j::ActiveNode
        has_many :in, :stops, model_class: 'DependentSpec::Stop', origin: :bands
        has_many :out, :routes, model_class: 'DependentSpec::Route', type: 'ON_ROUTE', depdent: :destroy
      end
    end

    context 'one level down' do
      before do
        DependentSpec::Route.reset_callbacks(:destroy)
        DependentSpec.setup_callback(:destroy)
        DependentSpec.setup_looping_callback(:destroy)
        [@route1, @philly, @boston].each(&:reload)
      end

      it 'do not loop endlessly' do
        [@route1, @philly, @boston].each { |node| expect(node).to be_persisted }
        expect { @route1.destroy }.not_to raise_error
        expect(@philly).not_to be_persisted
        expect(@boston).not_to be_persisted
        expect(DependentSpec::CALL_COUNT[:called]).to eq 2
      end
    end

    context 'depdencies within dependencies' do
      describe 'route1 stops everywhere, band4 only plays the last stop' do
        before do
          DependentSpec::Route.reset_callbacks(:destroy)
          DependentSpec.setup_callback(:destroy_orphans)
          [DependentSpec::Band, DependentSpec::Route, DependentSpec::Stop].each(&:delete_all)
          @route1 = DependentSpec::Route.create
          @route2 = DependentSpec::Route.create
          @stop1 = DependentSpec::Stop.create
          @stop2 = DependentSpec::Stop.create
          @stop3 = DependentSpec::Stop.create
          @stop4 = DependentSpec::Stop.create
          @stop5 = DependentSpec::Stop.create
          @route1.stops << [@stop1, @stop2, @stop3, @stop4, @stop5]
          @route2.stops << [@stop1, @stop2, @stop3]

          @band1 = DependentSpec::Band.create
          @band2 = DependentSpec::Band.create
          @band3 = DependentSpec::Band.create
          [@band1, @band2, @band3].each do |band|
            band.stops << [@stop1, @stop2]
          end

          @band4 = DependentSpec::Band.create
          @stop5.bands << @band4
        end

        it 'only destroys stop4, stop5, and band 4' do
          expect { @route1.destroy }.not_to raise_error
          [@band1, @band2, @band3].each { |band| expect(band).to be_persisted }
          expect(@band4).not_to be_persisted

          [@stop1, @stop2, @stop3].each { |stop| expect(stop).to be_persisted }
          [@stop4, @stop5].each { |stop| expect(stop).not_to be_persisted }
        end
      end
    end
  end
end
