require 'lucene/query_dsl'


# TODO DRY
require 'fileutils'  

require 'lucene'

include Lucene

$INDEX_DIR = 'var/index'


def delete_all_indexes
  FileUtils.rm_r $INDEX_DIR if File.directory? $INDEX_DIR
end

describe Lucene::QueryDSL, 'used from Index.find' do
  
  before(:each) do
    delete_all_indexes
    @index = Index.new($INDEX_DIR)    
    @index.clear
    @index << {:id => '42', :name => 'andreas', :foo => 'bar'}
    @doc = @index.uncommited['42']
    @index.commit
  end

  it "should find a simple dsl query" do
    hits = @index.find { name == 'andreas'}
    
    hits.size.should == 1
    hits.should include(@doc)
  end
  
  it "should find a simple dsl query" do
    hits = @index.find { (name == 'andreas') & (foo == 'bar')}
    
    hits.size.should == 1
    hits.should include(@doc)
  end
  
end

describe Lucene::QueryDSL do

  it "should parse & expressions" do
    expr = Lucene::QueryDSL.parse{ (name == 'andreas') & (age == [30..40])}
    expr.left.left.should == :name
    expr.left.right.should == 'andreas'
    
    expr.right.left.should == :age
    expr.right.right.should == [30..40]
  end
  
  it "should generate a lucene query" do
    expr = Lucene::QueryDSL.parse{ name == 'andreas' }
    query = expr.to_lucene(Lucene::FieldInfos.new(:id))
    
    query.should be_kind_of(Java::OrgApacheLuceneSearch::TermQuery)
    term = query.getTerm
    term.field.should == 'name'
    term.text.should == 'andreas'
  end

  
  it "should generate a lucene query" do
    expr = Lucene::QueryDSL.parse{ (name == 'andreas') & (age == 1) }
    query = expr.to_lucene(Lucene::FieldInfos.new(:id))
    
    query.should be_kind_of(Java::OrgApacheLuceneSearch::BooleanQuery)
        
    clauses = query.getClauses() 
    clauses.size.should == 2
    
    term0 = clauses[0].getQuery.getTerm
    term0.field.should == 'name'
    term0.text.should == 'andreas'

    term1 = clauses[1].getQuery.getTerm
    term1.field.should == 'age'
    term1.text.should == '1'
  end
  
  it "should handle range" do
    pending "need to refactor and reuse index_searcher.rb"
  end
  
end

