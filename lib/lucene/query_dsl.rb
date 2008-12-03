module Lucene
  
  class Expression
    attr_accessor :left, :right, :op, :query
  
    def self.new_complete(left, op, right)
      expr = Expression.new
      expr.left = left
      expr.op = op
      expr.right = right
      expr
    end
  
    def self.new_uncomplete(left, query)
      expr = Expression.new
      expr.left = left
      expr.query = query
      expr
    end
  
    def ==(other)
      @op = :==
        @right = other
      @query
    end
  
    def >(other)
      @op = :>
        @right = other
      @query
    end
  
    #
    # Returns the fields being used in a query
    #
    def _fields(fields = [])
      if (@left.kind_of? Expression)
        @left._fields(fields)
      else
        fields << @left
      end
      if (@right.kind_of? Expression)
        @right._fields(fields)
      end     
      fields
    end
    
    def to_lucene(field_infos)
      $LUCENE_LOGGER.debug{"QueryDSL.to_lucene '#{to_s}'"}
      
      if @left.kind_of? Lucene::Expression
        left_query = @left.to_lucene(field_infos)
        raise ArgumentError.new("Right term is not an Expression, but a '#{@right.class.to_s}'") unless @right.kind_of? Lucene::Expression
        right_query = @right.to_lucene(field_infos)
        query = org.apache.lucene.search.BooleanQuery.new
        clause = (@op == :&) ? org.apache.lucene.search.BooleanClause::Occur::MUST : org.apache.lucene.search.BooleanClause::Occur::SHOULD
        query.add(left_query, clause)
        query.add(right_query, clause)
        return query
      else
        field_info = field_infos[@left]
        field_info.convert_to_query(@left, @right)
      end
    end

    def to_s
      "(#@left #@op #@right)"
    end
  end
  
  class QueryDSL
    attr_reader :stack 
    
    def initialize
      @stack = []
      #yield self
    end
    
    def self.find(field_infos = IndexInfo.new(:id), &expr) 
      exp = QueryDSL.parse(&expr)
      exp.to_lucene(field_infos)
    end
      
    
  
    def self.parse(&query)
      query_dsl = QueryDSL.new
      query_dsl.instance_eval(&query)
      query_dsl.stack.last
    end
    
    def method_missing(methodname, *args)
      expr = Expression.new_uncomplete(methodname, self)
      @stack.push expr
      expr
    end
  
    def ==(other)
      puts "WRONG == '#{other}'"
    end
    
    def <=>(to)
      from = @stack.last.right
      @stack.last.right = Range.new(from, to)
      @stack.last
    end
  
  
    def &(other)
      raise ArgumentError.new("Expected at least two expression on stack, got #{@stack.size}") if @stack.size < 2
      right = @stack.pop
      left = @stack.pop
      expr = Expression.new_complete(left, :&, right)
      @stack.push expr
      self
    end

    def |(other)
      raise ArgumentError.new("Expected at least two expression on stack, got #{@stack.size}") if @stack.size < 2
      right = @stack.pop
      left = @stack.pop
      expr = Expression.new_complete(left, :|, right)
      @stack.push expr
      self
    end

    def to_s
      @stack.last.to_s
    end
      
  end
  
  
end

