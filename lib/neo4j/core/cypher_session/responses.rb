require 'neo4j/core/cypher_session/result'

module Neo4j
  module Core
    module CypherSession
      module Responses
        extend ActiveSupport::Concern

        included do
          attr_accessor :wrap_level
        end

        def result_from_data(entities_data)
          rows = entities_data.map do |entity_data|
            wrap(entity_data.values)
          end

          Neo4j::Core::CypherSession::Result.new(entities_data.keys, rows)
        end

        private

        def wrap(value)
          case value
          when Neo4j::Driver::Types::Entity
            wrap_by_level(value)
          when Neo4j::Driver::Types::Path
            value
          when Hash
            value.map { |key, val| [key, wrap(val)] }.to_h
          when Enumerable
            value.map(&method(:wrap))
          else
            value
          end
        end

        def wrap_by_level(entity)
          case wrap_level
          when :core_entity
            entity
          else
            entity.wrap
          end
        end
      end
    end
  end
end
