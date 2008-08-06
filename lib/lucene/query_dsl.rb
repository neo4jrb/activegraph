require 'lucene'

#require 'lucene/jars'
#require 'lucene/field_infos'

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
      puts "== '#{other}'"
      @op = :==
        @right = other
      @query
    end
  
    def >(other)
      puts "> '#{other}'"
      @op = :>
        @right = other
      @query
    end
  
    
    def to_lucene(field_infos)
      puts "TO Lucene '#{to_s}' #{@left.kind_of? Lucene::Expression}"
      
      if @left.kind_of? Lucene::Expression
        puts "Expressions #{@left} #{@right}"
        left_query = @left.to_lucene(field_infos)
        raise ArgumentError.new("Right term is not an Expression, but a '#{@right.class.to_s}'") unless @right.kind_of? Lucene::Expression
        right_query = @right.to_lucene(field_infos)
        query = BooleanQuery.new
        query.add(left_query, BooleanClause::Occur::MUST)
        query.add(right_query, BooleanClause::Occur::MUST)
        return query
      else
        key = @left
        value = @right
#        puts "Simple Term #{key} #{value}: type #{@left.class.to_s} #{@right.class.to_s}"
        field_info = field_infos[key]
        raise ArgumentError.new("Unknown field '#{key}'") if field_info.nil?
        converted_value = field_info.convert_to_lucene(value)
        term  = org.apache.lucene.index.Term.new(key.to_s, converted_value)        
        return TermQuery.new(term) 
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
    
    def self.find(field_infos = FieldInfos.new(:id), &expr) 
      exp = QueryDSL.parse(&expr)
      
      
      exp.to_lucene(field_infos)
    end
      
    
  
    def self.parse(&query)
      e = QueryDSL.new.instance_eval(&query)
      e.stack.last
    end
    
    def method_missing(methodname, *args)
      puts "called '#{methodname}'"
      expr = Expression.new_uncomplete(methodname, self)
      @stack.push expr
      expr
    end
  
    def ==(other)
      puts "WRONG == '#{other}'"
    end
  
  
    def &(other)
      raise ArgumentError.new("Expected at least two expression on stack, got #{@stack.size}") if @stack.size < 2
      right = @stack.pop
      left = @stack.pop
      expr = Expression.new_complete(left, :&, right)
      @stack.push expr
      puts "& '#{other}'"
      self
    end

    def to_s
      @stack.last.to_s
    end
      
  end
  
  
end

