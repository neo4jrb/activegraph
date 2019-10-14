require 'ostruct'

module Rails
  describe 'railtie' do
    require 'neo4j/railtie'


    around(:each) do |example|
      main_spec_session = Neo4j::ActiveBase.current_session
      example.run
      Neo4j::ActiveBase.current_session = main_spec_session
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
          stub_const('Neo4j::SessionManager', spy('Neo4j::SessionManager'))

          expect do
            Neo4j::Railtie.setup!(cfg)
          end.send(*raise_expectation)
        end

        context 'NEO4J_URL is bolt' do
          let_env_variable(:NEO4J_URL) { 'bolt://localhost:7472' }

          it 'calls Neo4j::SessionManager' do
            expect(Neo4j::SessionManager).to have_received(:open_neo4j_session).with('bolt://localhost:7472', {})
          end
        end
      end
    end
  end
end
