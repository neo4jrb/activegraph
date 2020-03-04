require 'active_graph/core/driver'

# The registry is necessary due to the specs constantly creating new Drivers.
# Closing a driver is costly. Not closing it prevents the process from termination.
# The registry allows reusage of drivers which are thread safe and conveniently closing them in one call.
class TestDriver < ActiveGraph::Core::Driver
  cattr_reader :cache, default: {}

  at_exit do
    close_all
  end

  class << self
    def new_instance(url, auth_token, options = {})
      cache[url] ||= super(url, auth_token, options.merge(encryption: false))
    end

    def close_all
      cache.values.each(&:close)
    end
  end

  def close; end
end
