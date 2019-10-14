require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/adaptors/schema'
require 'singleton'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        # The registry is necessary due to the specs constantly creating new CypherSessions.
        # Closing a driver is costly. Not closing it prevents the process from termination.
        # The registry allows reusage of drivers which are thread safe and conveniently closing them in one call.
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

        class Driver < Base
          include Adaptors::HasUri
          include Adaptors::Schema
          default_url('bolt://neo4:neo4j@localhost:7687')
          validate_uri do |uri|
            uri.scheme == 'bolt'
          end

          attr_reader :driver
          alias connected? driver

          def initialize(url, options = {})
            self.url = url
            @driver = DriverRegistry.instance.driver_for(url)
            @options = options
          end

          def connect; end

          def close
            DriverRegistry.instance.close(driver)
          end

          def query_set(transaction, queries, options = {})
            setup_queries!(queries, transaction, skip_instrumentation: options[:skip_instrumentation])

            responses = queries.map do |query|
              transaction.root_tx.run(query.cypher, query.parameters)
            end
            wrap_level = options[:wrap_level] || @options[:wrap_level]
            Responses.new(responses, wrap_level: wrap_level).to_a
          rescue Neo4j::Driver::Exceptions::Neo4jException => e
            raise Neo4j::Core::CypherSession::CypherError.new_from(e.code, e.message) # , e.stack_track.to_a
          end

          # def transaction(_session, &block)
          #   session = driver.session(org.neo4j.driver.v1.AccessMode::WRITE)
          #   session.writeTransaction(&block)
          # ensure
          #   session.close
          # end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/driver'
            Neo4j::Core::CypherSession::Transactions::Driver
          end

          instrument(:request, 'neo4j.core.bolt.request', %w[adaptor body]) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000
            adaptor = payload[:adaptor]

            type = nil # adaptor.ssl? ? '+TLS' : ' UNSECURE'
            " #{ANSI::BLUE}BOLT#{type}:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{adaptor.url_without_password}"
          end
        end
      end
    end
  end
end
