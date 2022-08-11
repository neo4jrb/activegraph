require 'ostruct'

module Rails
  describe 'railtie' do
    require 'active_graph/railtie'

    after(:context) { set_default_driver }

    describe '#setup!' do
      let(:driver_path) {}
      let(:cfg) do
        ActiveGraph::Railtie.empty_config.dup.tap do |c|
          c.driver.path = driver_path if driver_path
          c.driver.abc = 1
        end
      end

      let(:raise_expectation) { [:not_to, raise_error] }

      context 'no errors' do
        before do
          stub_const('Neo4j::Driver::GraphDatabase', spy('Neo4j::Driver::GraphDatabase'))

          expect do
            ActiveGraph::Railtie.setup!(cfg)
          end.send(*raise_expectation)
        end

        context 'NEO4J_URL is bolt' do
          let_env_variable(:NEO4J_URL) { 'bolt://localhost:7472' }

          it 'calls ActiveGraph::Base' do
            expect(Neo4j::Driver::GraphDatabase).to have_received(:driver).with('bolt://localhost:7472', Object, abc: 1)
          end
        end
      end
    end
  end
end
