module Neo4j::Shared
  module Cypher
    module CreateMethod
      def create_method
        creates_unique? ? :create_unique : :create
      end

      def creates_unique(option = :none)
        option = :none if option == true
        @creates_unique = option
      end

      def creates_unique_option
        @creates_unique || :none
      end

      def creates_unique?
        !!@creates_unique
      end
      alias_method :unique?, :creates_unique?
    end

    module RelIdentifiers
      extend ActiveSupport::Concern

      [:from_node, :to_node, :rel].each do |element|
        define_method("#{element}_identifier") do
          instance_variable_get(:"@#{element}_identifier") || element
        end

        define_method("#{element}_identifier=") do |id|
          instance_variable_set(:"@#{element}_identifier", id.to_sym)
        end
      end
    end
  end
end
