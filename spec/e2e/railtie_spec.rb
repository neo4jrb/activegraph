require 'ostruct'

module Rails
  describe 'railtie' do
    require 'active_graph/railtie'


    around(:each) do |example|
      main_spec_driver = ActiveGraph::Base.current_driver
      example.run
      ActiveGraph::Base.driver = main_spec_driver
    end

    describe '#setup!' do
      let(:driver_path) {}
      let(:cfg) do
        ActiveSupport::OrderedOptions.new.tap do |c|
          c.driver = ActiveSupport::OrderedOptions.new
          c.driver.path = driver_path if driver_path
        end
      end

      let(:raise_expectation) { [:not_to, raise_error] }

      context 'no errors' do
        before do
          stub_const('ActiveGraph::Base', spy('ActiveGraph::Base'))

          expect do
            ActiveGraph::Railtie.setup!(cfg)
          end.send(*raise_expectation)
        end

        context 'NEO4J_URL is bolt' do
          let_env_variable(:NEO4J_URL) { 'bolt://localhost:7472' }

          it 'calls ActiveGraph::Base' do
            expect(ActiveGraph::Base).to have_received(:new_driver).with('bolt://localhost:7472', {})
          end
        end
      end
    end
  end
end
