require 'ostruct'

module Rails
  describe 'railtie' do
    require 'neo4j/railtie'


    around(:each) do |example|
      main_spec_driver = Neo4j::ActiveBase.current_driver
      example.run
      Neo4j::ActiveBase.driver = main_spec_driver
    end

    describe '#setup!' do
      let(:session_path) {}
      let(:cfg) do
        ActiveSupport::OrderedOptions.new.tap do |c|
          c.session = ActiveSupport::OrderedOptions.new
          c.session.path = session_path if session_path
        end
      end

      let(:raise_expectation) { [:not_to, raise_error] }

      context 'no errors' do
        before do
          stub_const('Neo4j::ActiveBase', spy('Neo4j::ActiveBase'))

          expect do
            Neo4j::Railtie.setup!(cfg)
          end.send(*raise_expectation)
        end

        context 'NEO4J_URL is bolt' do
          let_env_variable(:NEO4J_URL) { 'bolt://localhost:7472' }

          it 'calls Neo4j::ActiveBase' do
            expect(Neo4j::ActiveBase).to have_received(:new_driver).with('bolt://localhost:7472', {})
          end
        end
      end
    end
  end
end
