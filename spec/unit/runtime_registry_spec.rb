require 'active_graph/runtime_registry'

RSpec.describe ActiveGraph::RuntimeRegistry do
  before do
    described_class.reset
  end

  after do
    described_class.reset
  end

  describe '.call' do
    it 'accumulates database runtime' do
      described_class.call('neo4j.core.bolt.request', 1.0, 1.25, 'id', {})

      expect(described_class.reset).to eq(250.0)
    end

    it 'accumulates runtime across multiple database requests' do
      described_class.call('neo4j.core.bolt.request', 1.0, 1.25, 'id', {})
      described_class.call('neo4j.core.bolt.request', 2.0, 2.5, 'id', {})

      expect(described_class.reset).to eq(750.0)
    end
  end

  describe '.reset' do
    it 'clears the accumulated runtime' do
      described_class.call('neo4j.core.bolt.request', 1.0, 1.25, 'id', {})

      described_class.reset

      expect(described_class.reset).to eq(0.0)
    end
  end
end