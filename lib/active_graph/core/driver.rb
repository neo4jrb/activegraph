require 'active_support/core_ext/module/attribute_accessors'
require 'active_graph/core/logging'
require 'active_graph/version'

module ActiveGraph
  module Core
    class Driver
      USER_AGENT_STRING = "activegraph-gem/#{::ActiveGraph::VERSION} (https://github.com/neo4jrb/activegraph)"

      attr_accessor :wrap_level
      attr_reader :options, :driver, :url
      delegate :close, to: :driver

      class << self
        def new_instance(url, auth_token,  options = {})
          Neo4j::Driver::GraphDatabase.driver(url, auth_token, options)
        end
      end

      def initialize(url, auth_token = Neo4j::Driver::AuthTokens.none, options = {}, extended_options = {})
        @url = url
        @driver = self.class.new_instance(url, auth_token, options)
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
