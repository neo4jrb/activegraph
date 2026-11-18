require 'active_graph/railties/controller_runtime'

RSpec.describe ActiveGraph::Railties::ControllerRuntime do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include ActiveGraph::Railties::ControllerRuntime

      def index
      end
    end
  end

  let(:controller) { controller_class.new }

  before do
    ActiveGraph::RuntimeRegistry.reset
  end

  after do
    ActiveGraph::RuntimeRegistry.reset
  end

  describe '#append_info_to_payload' do
    it 'adds database runtime to the payload' do
      ActiveGraph::RuntimeRegistry.call(
        'neo4j.core.bolt.request',
        1.0,
        1.25,
        'id',
        {}
      )

      payload = {}

      controller.send(:append_info_to_payload, payload)

      expect(payload[:db_runtime]).to eq(250.0)
    end

    it 'preserves existing database runtime in the payload' do
      ActiveGraph::RuntimeRegistry.call(
        'neo4j.core.bolt.request',
        1.0,
        1.25,
        'id',
        {}
      )

      payload = { db_runtime: 100.0 }

      controller.send(:append_info_to_payload, payload)

      expect(payload[:db_runtime]).to eq(350.0)
    end
  end

  describe '#process_action' do
    it 'resets database runtime before processing the action' do
      ActiveGraph::RuntimeRegistry.call(
        'neo4j.core.bolt.request',
        1.0,
        1.25,
        'id',
        {}
      )

      expect(ActiveGraph::RuntimeRegistry).to receive(:reset).and_call_original

      controller.send(:process_action, :index)
    end
  end
end