require 'active_support/core_ext/module/attribute_accessors'
require 'neo4j/core/logging'
require 'neo4j/core/has_uri'
require 'neo4j/core/schema'
require 'neo4j/core/querable'

module Neo4j
  module Core
    class Driver
      include HasUri
      include Schema
      include Querable

      USER_AGENT_STRING = "neo4j-gem/#{::Neo4j::VERSION} (https://github.com/neo4jrb/neo4j)"

      cattr_reader :singleton
      attr_accessor :wrap_level
      attr_reader :options, :driver
      delegate :close, to: :driver

      @@mutex = Mutex.new
      at_exit do
        close
      end

      default_url('bolt://neo4:neo4j@localhost:7687')

      validate_uri do |uri|
        uri.scheme == 'bolt'
      end

      class << self
        def singleton=(driver)
          @@mutex.synchronize do
            singleton&.close
            class_variable_set(:@@singleton, driver)
          end
        end

        def new_instance(url)
          uri = URI(url)
          user = uri.user
          password = uri.password
          auth_token = if user
                         Neo4j::Driver::AuthTokens.basic(user, password)
                       else
                         Neo4j::Driver::AuthTokens.none
                       end
          Neo4j::Driver::GraphDatabase.driver(url, auth_token)
        end

        def close
          singleton&.close
        end
      end

      def initialize(url, options = {})
        self.url = url
        @driver = self.class.new_instance(url)
        self.class.singleton = self
        @options = options
      end

      def logger
        return @logger if @logger

        @logger = if @options[:logger]
                    @options[:logger]
                  else
                    Logger.new(logger_location).tap do |logger|
                      logger.level = logger_level
                    end
                  end
      end

      private

      def logger_location
        @options[:logger_location] || STDOUT
      end

      def logger_level
        @options[:logger_level] || Logger::WARN
      end
    end
  end
end
