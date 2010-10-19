module Neo4j
  module Index

    class WrappedQuery
      include Enumerable

      def initialize(index, query)
        @index = index
        @query = query
      end

      def each
        hits.each { |n| yield n.wrapper }
      end

      def close
        @hits.close if @hits
      end

      def empty?
        hits.size == 0
      end

      def size
        hits.size
      end

      def hits
        @hits ||= perform_query
      end

      def desc(*fields)
        @order = fields.inject(@order || {}) { |memo, field| memo[field] = true; memo }
        self
      end

      def asc(*fields)
        @order = fields.inject(@order || {}) { |memo, field| memo[field] = false; memo }
        self
      end

      def perform_query
        if @order
          java_sort_fields = @order.keys.inject([]) do |memo, field|
            memo << org.apache.lucene.search.SortField.new(field.to_s, org.apache.lucene.search.SortField::STRING, @order[field])
          end
          sort = org.apache.lucene.search.Sort.new(*java_sort_fields)
          @query = org.neo4j.index.impl.lucene.QueryContext.new(@query).sort(sort)
        end
        @index.query(@query)
      end
    end
  end
end

