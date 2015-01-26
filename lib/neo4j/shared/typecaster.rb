module Neo4j
  module Shared
    module Typecaster
      def self.included(other)
        Neo4j::Shared::TypeConverters.register_converter(other)
      end
    end
  end
end
