module ActiveGraph
  module Core
    module Result
      attr_writer :wrap

      def wrap?
        @wrap
      end

      def each(&block)
        wrap? ? wrapping_each(&block) : super
      end

      private

      def wrapping_each(&block)
        if @records
          @records.each(&block)
        else
          @records = []
          method(:each).super_method.call do |record|
            record.wrap = wrap?
            @records << record
            block_given? ? yield(record) : record
          end
        end
      end
    end
  end
end
