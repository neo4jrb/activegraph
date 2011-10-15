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
      include WillPaginate::Finders::Base
      attr_accessor :left_and_query, :left_or_query

      def initialize(index, decl_props, query, params={})
        @index      = index
        @query      = query
        @decl_props = decl_props
        @params     = params

        if params.include?(:sort)
          @order = {}
          params[:sort].each_pair { |k, v| @order[k] = (v == :desc) }
        end
      end

      def wp_query(options, pager, args, &block) #:nodoc:
        @params[:page]     = pager.current_page
        @params[:per_page] = pager.per_page
        pager.replace [*self]
        pager.total_entries = size
      end

      # Since we include the Ruby Enumerable mixin we need this method.
      def each
        if @params.include?(:per_page)
          # paginate the result, used by the will_paginate gem
          page     = @params[:page] || 1
          per_page = @params[:per_page]
          to       = per_page * page
          from     = to - per_page
          i        = 0
          hits.each do |node|
            yield node.wrapper if i >= from
            i += 1
            break if i >= to
          end
        else
          hits.each { |n| yield n.wrapper }
        end
      end

      # Close hits
      #
      # Closes the underlying search result. This method should be called whenever you've got what you wanted from the result and won't use it anymore.
      # It's necessary to call it so that underlying indexes can dispose of allocated resources for this search result.
      # You can however skip to call this method if you loop through the whole result, then close() will be called automatically.
      # Even if you loop through the entire result and then call this method it will silently ignore any consequtive call (for convenience).
      #
      # This must be done according to the Neo4j Java Documentation:
      def close
        @hits.close if @hits
        @hits = nil
      end

      # True if there is no search hits.
      def empty?
        hits.size == 0
      end

      # returns the n'th search item
      # Does simply loop all search items till the n'th is found.
      #
      def [](index)
        i = 0
        each{|x| return x if i == index; i += 1}
        nil # out of index
      end

      # Returns the number of search hits
      def size
        hits.size
      end

      def hits #:nodoc:
        close
        @hits = perform_query
      end

      # Performs a range query
      # Notice that if you don't specify a type when declaring a property a String range query will be performed.
      #
      def between(lower, upper, lower_incusive=false, upper_inclusive=false)
        raise "Expected a symbol. Syntax for range queries example: index(:weight).between(a,b)" unless Symbol === @query
        raise "Can't only do range queries on Neo4j::NodeMixin, Neo4j::Model, Neo4j::RelationshipMixin" unless @decl_props
        # check that we perform a range query on the same values as we have declared with the property :key, :type => ...
        type = @decl_props[@query] && @decl_props[@query][:type]
        raise "find(#{@query}).between(#{lower}, #{upper}): #{lower} not a #{type}" if type && !type === lower.class
        raise "find(#{@query}).between(#{lower}, #{upper}): #{upper} not a #{type}" if type && !type === upper.class

        # Make it possible to convert those values
        @query = range_query(@query, lower, upper, lower_incusive, upper_inclusive)
        self
      end

      def range_query(field, lower, upper, lower_incusive, upper_inclusive)
        lower = TypeConverters.convert(lower)
        upper = TypeConverters.convert(upper)

        case lower
          when Fixnum
            org.apache.lucene.search.NumericRangeQuery.new_long_range(field.to_s, lower, upper, lower_incusive, upper_inclusive)
          when Float
            org.apache.lucene.search.NumericRangeQuery.new_double_range(field.to_s, lower, upper, lower_incusive, upper_inclusive)
          else
            org.apache.lucene.search.TermRangeQuery.new(field.to_s, lower, upper, lower_incusive, upper_inclusive)
        end
      end


      # Create a compound lucene query.
      #
      # ==== Parameters
      # query2 :: the query that should be AND together
      #
      # ==== Example
      #
      #  Person.find(:name=>'kalle').and(:age => 3)
      #
      def and(query2)
        new_query                = LuceneQuery.new(@index, @decl_props, query2)
        new_query.left_and_query = self
        new_query
      end


      # Sort descending the given fields.
      def desc(*fields)
        @order = fields.inject(@order || {}) { |memo, field| memo[field] = true; memo }
        self
      end

      # Sort ascending the given fields.
      def asc(*fields)
        @order = fields.inject(@order || {}) { |memo, field| memo[field] = false; memo }
        self
      end

      def build_and_query(query) #:nodoc:
        left_query = @left_and_query.build_query
        and_query  = org.apache.lucene.search.BooleanQuery.new
        and_query.add(left_query, org.apache.lucene.search.BooleanClause::Occur::MUST)
        and_query.add(query, org.apache.lucene.search.BooleanClause::Occur::MUST)
        and_query
      end

      def build_sort_query(query) #:nodoc:
        java_sort_fields = @order.keys.inject([]) do |memo, field|
          decl_type = @decl_props && @decl_props[field] && @decl_props[field][:type]
          type      = case
                        when Float == decl_type
                          org.apache.lucene.search.SortField::DOUBLE
                        when Fixnum == decl_type || DateTime == decl_type || Date == decl_type || Time == decl_type
                          org.apache.lucene.search.SortField::LONG
                        else
                          org.apache.lucene.search.SortField::STRING
                      end
          memo << org.apache.lucene.search.SortField.new(field.to_s, type, @order[field])
        end
        sort             = org.apache.lucene.search.Sort.new(*java_sort_fields)
        org.neo4j.index.lucene.QueryContext.new(query).sort(sort)
      end

      def build_hash_query(query) #:nodoc:
        and_query = org.apache.lucene.search.BooleanQuery.new

        query.each_pair do |key, value|
          type = @decl_props && @decl_props[key.to_sym] && @decl_props[key.to_sym][:type]
          if !type.nil? && type != String
            if Range === value
              and_query.add(range_query(key, value.first, value.last, true, !value.exclude_end?), org.apache.lucene.search.BooleanClause::Occur::MUST)
            else
              and_query.add(range_query(key, value, value, true, true), org.apache.lucene.search.BooleanClause::Occur::MUST)
            end
          else
            conv_value = type ? TypeConverters.convert(value) : value.to_s
            term       = org.apache.lucene.index.Term.new(key.to_s, conv_value)
            term_query = org.apache.lucene.search.TermQuery.new(term)
            and_query.add(term_query, org.apache.lucene.search.BooleanClause::Occur::MUST)
          end
        end
        and_query
      end

      def build_query #:nodoc:
        query = @query
        query = build_hash_query(query) if Hash === query
        query = build_and_query(query) if @left_and_query
        query = build_sort_query(query) if @order
        query
      end

      def perform_query #:nodoc:
        @index.query(build_query)
      end
    end
  end
end

