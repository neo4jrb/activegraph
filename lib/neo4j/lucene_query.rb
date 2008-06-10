module Neo4j

  module LuceneQuery
  
    # import java classes
    IndexReader = org.apache.lucene.index.IndexReader
    Term = org.apache.lucene.index.Term
    IndexWriter = org.apache.lucene.index.IndexWriter    
    Document = org.apache.lucene.document.Document
    StandardAnalyzer = org.apache.lucene.analysis.standard.StandardAnalyzer
    Field = org.apache.lucene.document.Field
    
    TermQuery = org.apache.lucene.search.TermQuery  
    MultiTermQuery = org.apache.lucene.search.MultiTermQuery    
    BooleanClause = org.apache.lucene.search.BooleanClause
    BooleanQuery  = org.apache.lucene.search.BooleanQuery
    IndexSearcher = org.apache.lucene.search.IndexSearcher

 
  
    #
    # Finds the node ids using the index at the given location and
    # having the specified fields
    #
    #
    def find(index_path, fields)
      # are there any index for this node ?
      # if not return an empty array
      return [] unless File.directory? index_path
      
      query = BooleanQuery.new
      
      fields.each_pair do |key,value|  
        term  = Term.new(key.to_s, value.to_s)        
        q = TermQuery.new(term)
        query.add(q, BooleanClause::Occur::MUST)
      end

      engine = IndexSearcher.new(index_path)
      hits = engine.search(query).iterator
      results = []
      while (hits.hasNext && hit = hits.next)
        id = hit.getDocument.getField("id").stringValue.to_i
        results <<  id #[hit.getScore, id, text]
      end
      engine.close
      results
    end

  
    module_function :find
  end

end
