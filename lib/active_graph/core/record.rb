require 'active_graph/core/result'
require 'active_support/core_ext/module/attribute_accessors'

module ActiveGraph
  module Core
    module Record
      attr_writer :wrap

      def values
         wrap(super)
      end

      def first
        wrap(super)
      end

      def [](key)
         wrap(super)
      end

      def to_h
         wrap(super)
      end

      private

      def wrap(value)
        return value unless wrap?

        case value
        when Neo4j::Driver::Types::Entity
          value.wrap
        when Neo4j::Driver::Types::Path
          value
        when Hash
          value.transform_values(&method(:wrap))
        when Enumerable
          value.map!(&method(:wrap))
        else
          value
        end
      end

      def wrap?
        @wrap
      end
    end
  end
end
