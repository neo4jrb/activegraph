module Neo4j
  module Index
    # == LuceneQuery
    #
    # This object is returned when you call the #find method on the Node, Relationship.
    # The actual query is not executed until the first item is requested.
    #
    # You can perform a query in many different ways:
    #
    # ==== By Hash
    #
    # Example:
    #  Person.find(:name => 'foo', :age => 3)
    #
    # ==== By Range
    #
    # Example:
    #  Person.find(:age).between(15,35)
    #
    # ==== By Lucene Query Syntax
    #
    # Example
    #  Car.find('wheels:"4" AND colour: "blue")
    #
    # For more information about the syntax see http://lucene.apache.org/java/3_0_2/queryparsersyntax.html
    #
    # ==== By Compound Queries
    #
    # You can combine several queries by <tt>AND</tt>ing those together.
    #
    # Example:
    #   Vehicle.find(:weight).between(5.0, 100000.0).and(:name).between('a', 'd')
    #
    # === See Also
    # * Neo4j::Index::Indexer#index
    # * Neo4j::Index::Indexer#find - which returns an LuceneQuery
    #
    class LuceneQuery
      include Enumerable
      attr_accessor :left_and_query, :left_or_query
      
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
          @query = org.apache.lucene.search.NumericRangeQuery.new_double_range(@query.to_s, lower, upper, false, false)
        else
          raise "find(#{@query}).between(#{lower}, #{upper}) to allowed since #{lower} is not a String" if lower === String
          raise "find(#{@query}).between(#{lower}, #{upper}) to allowed since #{upper} is not a String" if upper === String
          @query = org.apache.lucene.search.TermRangeQuery.new(@query.to_s, lower, upper, false, false)
        end
        self
      end

      def and(query2)
        new_query = LuceneQuery.new(@index, @decl_props, query2)
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

      def build_and_query(query)
        left_query = @left_and_query.build_query
        and_query  = org.apache.lucene.search.BooleanQuery.new
        and_query.add(left_query, org.apache.lucene.search.BooleanClause::Occur::MUST)
        and_query.add(query, org.apache.lucene.search.BooleanClause::Occur::MUST)
        and_query
      end

      def build_sort_query(query)
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
      end

      def build_hash_query(query)
        and_query  = org.apache.lucene.search.BooleanQuery.new

        query.each_pair do |key, value|
          raise "Only String values valid in find(hash) got :#{key} => #{value} which is not a String" if !value.is_a?(String) && @decl_props[key] && @decl_props[key][:type] != String
          term = org.apache.lucene.index.Term.new(key.to_s, value.to_s)
          term_query = org.apache.lucene.search.TermQuery.new(term)
          and_query.add(term_query, org.apache.lucene.search.BooleanClause::Occur::MUST)
        end
        and_query
      end
      
      def build_query
        query = @query
        query = build_hash_query(query) if Hash === query
        query = build_and_query(query) if @left_and_query
        query = build_sort_query(query) if @order
        query
      end

      def perform_query
        @index.query(build_query)
      end
    end
  end
end

