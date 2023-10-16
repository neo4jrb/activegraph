module ActiveGraph
  module Core
    module Result
      attr_writer :wrap

      def keys
        @keys ||= super
      end

      def wrap?
        @wrap
      end

      def each(&block)
        store if wrap? # TODO: why? This is preventing streaming
        @records&.each(&block) || super
      end

      ## To avoid to_a on Neo4j::Driver::Result as that one does not call the above block
      def to_a
        map.to_a
      end

      def store
        return if @records
        keys
        @records = []
        # TODO: implement 'each' without block parameter
        method(:each).super_method.call do |record|
          record.wrap = wrap?
          @records << record
        end
      end
    end
  end
end
