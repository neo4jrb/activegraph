require 'active_support/core_ext/module/attribute_accessors'
require 'neo4j/core/logging'
require 'neo4j/core/has_uri'
require 'neo4j/version'

module Neo4j
  module Core
    class Driver
      include HasUri

      USER_AGENT_STRING = "neo4j-gem/#{::Neo4j::VERSION} (https://github.com/neo4jrb/neo4j)"

      attr_accessor :wrap_level
      attr_reader :options, :driver
      delegate :close, to: :driver

      default_url('bolt://neo4:neo4j@localhost:7687')

      validate_uri do |uri|
        uri.scheme == 'bolt'
      end

      class << self
        def new_instance(url, options = {})
          uri = URI(url)
          user = uri.user
          password = uri.password
          auth_token = if user
                         Neo4j::Driver::AuthTokens.basic(user, password)
                       else
                         Neo4j::Driver::AuthTokens.none
                       end
          Neo4j::Driver::GraphDatabase.driver(url, auth_token, options)
        end
      end

      def initialize(url, options = {}, extended_options = {})
        self.url = url
        @driver = self.class.new_instance(url, options)
        @options = extended_options
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
