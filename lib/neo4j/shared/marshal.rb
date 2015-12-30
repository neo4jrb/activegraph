module Neo4j
  module Shared
    module Marshal
      extend ActiveSupport::Concern

      def marshal_dump
        marshal_instance_variables.map(&method(:instance_variable_get))
      end

      def marshal_load(array)
        marshal_instance_variables.zip(array).each(&method(:instance_variable_set))
      end

      private

      def marshal_instance_variables
        self.class::MARSHAL_INSTANCE_VARIABLES
      end
    end
  end
end
