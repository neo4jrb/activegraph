require 'spec_helper'
require 'active_graph/core/driver'
require 'neo4j/driver'

def port
  URI(ENV['NEO4J_URL']).port
end

describe ActiveGraph::Core::Driver do
  let(:url) { ENV['NEO4J_URL'] }

  # let(:driver) { ActiveGraph::Core::Adaptors::Driver.new(url, logger_level: Logger::DEBUG) }
  let(:driver) { TestDriver.new(url) }

  after(:context) do
    # ActiveGraph::Core::DriverRegistry.instance.close_all
  end

  subject { driver }

  describe '#initialize' do
    let_context(url: 'url') { subject_should_raise ArgumentError, /Invalid address format/ }
    let_context(url: :symbol) { subject_should_raise ArgumentError }
    let_context(url: 123) { subject_should_raise ArgumentError }

    let_context(url: "http://localhost:#{port}") do
      subject_should_raise Neo4j::Driver::Exceptions::ClientException, /Unsupported URI scheme/
    end
    let_context(url: "http://foo:bar@localhost:#{port}") do
      subject_should_raise Neo4j::Driver::Exceptions::ClientException, /Unsupported URI scheme/
    end
    let_context(url: "https://localhost:#{port}") do
      subject_should_raise Neo4j::Driver::Exceptions::ClientException, /Unsupported URI scheme/
    end
    let_context(url: "https://foo:bar@localhost:#{port}") do
      subject_should_raise Neo4j::Driver::Exceptions::ClientException, /Unsupported URI scheme/
    end

    let_context(url: 'bolt://foo@localhost:') { port == '7687' ? subject_should_not_raise : subject_should_raise }
    let_context(url: "bolt://:foo@localhost:#{port}") { subject_should_not_raise }

    let_context(url: "bolt://localhost:#{port}") { subject_should_not_raise }
    let_context(url: "bolt://foo:bar@localhost:#{port}") { subject_should_not_raise }
  end
end
