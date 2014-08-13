module Neo4j::ActiveNode
  module SerializedProperties
    extend ActiveSupport::Concern

    def serialized_properties
      self.class.serialized_properties
    end

    module ClassMethods

      def serialized_properties
        @serialize || {}
      end

      def serialize(name, coder = JSON)
        @serialize ||= {}
        @serialize[name] = coder
      end
    end
  end
end
