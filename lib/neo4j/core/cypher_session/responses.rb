require 'neo4j/core/cypher_session/result'

module Neo4j
  module Core
    module CypherSession
      class Responses
        include Enumerable

        def initialize(responses, options = {})
          @responses = responses
          @wrap_level = options[:wrap_level] || Neo4j::Core::Config.wrapping_level
        end

        def each
          @responses.each do |response|
            yield result_from_data(response)
          end
        end

        private

        def result_from_data(entities_data)
          rows = entities_data.map do |entity_data|
            wrap(entity_data.values)
          end

          Neo4j::Core::CypherSession::Result.new(entities_data.keys, rows)
        end

        def wrap(value)
          case value
          when Array
            value.map(&method(:wrap))
          when Hash
            value.map { |key, val| [key, wrap(val)] }.to_h
          when Neo4j::Driver::Types::Entity
            wrap_by_level(value)
          else
            value
          end
        end

        def wrap_by_level(entity)
          case @wrap_level
          when :core_entity
            entity
          when :proc
            entity.wrap
          else
            fail ArgumentError, "Invalid wrap_level: #{@wrap_level.inspect}"
          end
        end
      end
    end
  end
end
