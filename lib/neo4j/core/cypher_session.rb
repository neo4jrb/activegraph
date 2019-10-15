require 'active_support/core_ext/module/delegation'

module Neo4j
  module Core
    class CypherSession
      attr_reader :adaptor
      delegate :close, to: :adaptor

      def initialize(adaptor)
        @adaptor = adaptor
      end

      %w[
        query
        queries

        transaction

        version

        indexes
        constraints
      ].each do |method, &_block|
        define_method(method) do |*args, &block|
          @adaptor.send(method, self, *args, &block)
        end
      end
    end
  end
end
