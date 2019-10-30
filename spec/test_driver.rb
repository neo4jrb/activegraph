require 'neo4j/core/cypher_session/driver'

# The registry is necessary due to the specs constantly creating new Drivers.
# Closing a driver is costly. Not closing it prevents the process from termination.
# The registry allows reusage of drivers which are thread safe and conveniently closing them in one call.
class TestDriver < Neo4j::Core::CypherSession::Driver
  cattr_reader :cache, default: {}

  at_exit do
    close_all
  end

  default_url('bolt://neo4:neo4j@localhost:7687')

  validate_uri do |uri|
    uri.scheme == 'bolt'
  end

  class << self
    def new_instance(url)
      cache[url] ||= super
    end

    def close_all
      cache.values.each(&:close)
    end
  end

  def close; end
end
