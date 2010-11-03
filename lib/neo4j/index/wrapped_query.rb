module Neo4j
  module Index

    class WrappedQuery
      include Enumerable
      attr_accessor :left_and_query
      def initialize(index, decl_props, query)
        @index = index
        @query = query
        @decl_props = decl_props
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

      def [](index)
        each_with_index {|node,i| break node if index == i}
      end

      def size
        hits.size
      end

      def hits
        @hits ||= perform_query
      end

      def between(lower, upper)

        raise "Expected a symbol. Syntax for range queries example: index(:weight).between(a,b)" unless Symbol === @query
        raise "Can't only do range queries on Neo4j::NodeMixin, Neo4j::Model, Neo4j::RelationshipMixin" unless @decl_props
        type = @decl_props[@query] && @decl_props[@query][:type] 
        raise "Missing type declaration of property #{@query}. E.g. property :#{@query}, :type => Float; index :#{@query}" unless type
        if type != String
          raise "find(#{@query}).between(#{lower}, #{upper}) to allowed since #{lower} is not a Float or Fixnum" if lower === Float or lower === Fixnum
          raise "find(#{@query}).between(#{lower}, #{upper}) to allowed since #{upper} is not a Float or Fixnum" if upper === Float or upper === Fixnum
          puts "type=#{type} NUmeric #{lower}/#{lower.class} upper #{upper}/#{upper.class}"
          @query = org.apache.lucene.search.NumericRangeQuery.new_double_range(@query.to_s, lower, upper, false, false)
        else
          raise "find(#{@query}).between(#{lower}, #{upper}) to allowed since #{lower} is not a String" if lower === String
          raise "find(#{@query}).between(#{lower}, #{upper}) to allowed since #{upper} is not a String" if upper === String

          puts "TERM RANGE"
          @query = org.apache.lucene.search.TermRangeQuery.new(@query.to_s, lower, upper, false, false)
        end

        puts "GOT RANGE #{@query}"
        self
      end

      def and(query2)
        new_query = WrappedQuery.new(@index, @decl_props, query2)
        new_query.left_and_query = self
        new_query
      end

      def desc(*fields)
        @order = fields.inject(@order || {}) { |memo, field| memo[field] = true; memo }
        self
      end

      def asc(*fields)
        @order = fields.inject(@order || {}) { |memo, field| memo[field] = false; memo }
        self
      end

      def build_query
        query = if @left_and_query
                  puts "LEFT AND QUERY #{@left_and_query}"
                  left_query = @left_and_query.build_query
                  occur      = org.apache.lucene.search.BooleanClause::Occur::MUST
                  and_query  = org.apache.lucene.search.BooleanQuery.new
                  and_query.add(left_query, occur)
                  and_query.add(@query, occur)
                  and_query
                else
                  @query
                end


        query = begin
          java_sort_fields = @order.keys.inject([]) do |memo, field|
            decl_type = @decl_props && @decl_props[field] && @decl_props[field][:type]
            type      = case
                          when Float == decl_type
                            org.apache.lucene.search.SortField::DOUBLE
                          when Fixnum == decl_type
                            org.apache.lucene.search.SortField::LONG
                          else
                            org.apache.lucene.search.SortField::STRING
                        end
            memo << org.apache.lucene.search.SortField.new(field.to_s, type, @order[field])
          end
          sort             = org.apache.lucene.search.Sort.new(*java_sort_fields)
          org.neo4j.index.impl.lucene.QueryContext.new(query).sort(sort)
        end if @order

        query
      end

      def perform_query
        q = build_query
        puts "query = '#{@query} built #{q}'"
        @index.query(q)
      end
    end
  end
end

