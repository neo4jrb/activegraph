module ActiveGraph
  module Core
    class Result
      attr_reader :columns, :rows

      def initialize(columns, rows)
        @columns = columns.map(&:to_sym)
        @rows = rows
        @struct_class = Struct.new(:index, *@columns)
      end

      include Enumerable

      def each
        structs.each do |struct|
          yield struct
        end
      end

      def structs
        @structs ||= rows.each_with_index.map do |row, index|
          @struct_class.new(index, *row)
        end
      end

      def hashes
        @hashes ||= rows.map do |row|
          Hash[@columns.zip(row)]
        end
      end
    end
  end
end
