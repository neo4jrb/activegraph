include Java

module Lucene
  require 'lucene/jars/lucene-core-2.3.2.jar'
  
  # define some constants so that we don't have to write the package names all the time
  IndexReader = org.apache.lucene.index.IndexReader
  IndexWriter = org.apache.lucene.index.IndexWriter    
  StandardAnalyzer = org.apache.lucene.analysis.standard.StandardAnalyzer
    
  Term = org.apache.lucene.index.Term
  TermQuery = org.apache.lucene.search.TermQuery  
  MultiTermQuery = org.apache.lucene.search.MultiTermQuery    
  BooleanClause = org.apache.lucene.search.BooleanClause
  BooleanQuery  = org.apache.lucene.search.BooleanQuery
  IndexSearcher = org.apache.lucene.search.IndexSearcher

end