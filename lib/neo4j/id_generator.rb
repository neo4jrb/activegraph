module Neo4j
  module IdGenerator

    module Strategies

      class Strategy

        def self.make_uniq
          raise NotImplementedError
        end

      end

      class SecureRandomUUID < Strategy

        def self.make_uniq
          SecureRandom.uuid
        end

      end

    end

    UnknowIdGeneratorStrategy = Class.new(StandardError)

    class Builder

      AVAILABLE_STRATEGIES = {
        :secure_random_uuid => IdGenerator::Strategies::SecureRandomUUID
      }

      def initialize(strategy=:secure_random_uuid)
        raise UnknowIdGeneratorStrategy unless AVAILABLE_STRATEGIES.include?(strategy)
        @current_strategy_class = AVAILABLE_STRATEGIES[strategy]
      end

      def call
        @current_strategy_class.make_uniq
      end

    end

  end
end