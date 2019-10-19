# The registry is necessary due to the specs constantly creating new CypherSessions.
# Closing a driver is costly. Not closing it prevents the process from termination.
# The registry allows reusage of drivers which are thread safe and conveniently closing them in one call.
module Neo4j
  module Core
    module CypherSession
      class DriverRegistry < Hash
        include Singleton

        at_exit do
          instance.close_all
        end

        def initialize
          super
          @mutex = Mutex.new
        end

        def driver_for(url)
          uri = URI(url)
          user = uri.user
          password = uri.password
          auth_token = if user
                         Neo4j::Driver::AuthTokens.basic(user, password)
                       else
                         Neo4j::Driver::AuthTokens.none
                       end
          @mutex.synchronize { self[url] ||= Neo4j::Driver::GraphDatabase.driver(url, auth_token) }
        end

        def close(driver)
          delete(key(driver))
          driver.close
        end

        def close_all
          values.each(&:close)
          clear
        end
      end
    end
  end
end
