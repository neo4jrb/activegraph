# 
# Stolen code from http://markwatson.com/blog/2007/06/using-lucene-with-jruby.html
#

module Neo4j
  

  class Lucene
  
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

 
    @index_path = nil
    def initialize(an_index_path = "data/")
      @index_path = an_index_path
    end
  

    def index(id, fields)
      index_available = IndexReader.index_exists(@index_path)
      index_writer = IndexWriter.new(@index_path, StandardAnalyzer.new, !index_available)
      
      term_to_delete = Term.new('id', id) # if it exists
      doc   = Document.new
      doc.add(Field.new('id', id, Field::Store::YES, Field::Index::NO_NORMS))
    
      fields.each_pair do |key, value|  
#        puts "index #{key} = #{value}"
        value = '' if value.nil?
        doc.add(Field.new(key,value, Field::Store::YES, Field::Index::NO_NORMS))                               
      end
      
      index_writer.updateDocument(term_to_delete, doc) # delete any old docs with same id
      index_writer.close
    end

    
    def add_documents id_text_pair_array # e.g., [[1,"test1"],[2,'test2']]
      index_available = IndexReader.index_exists(@index_path)
      index_writer = IndexWriter.new(@index_path, StandardAnalyzer.new, !index_available)
      id_text_pair_array.each {|id_text_pair|
        term_to_delete = Term.new("id", id_text_pair[0].to_s) # if it exists
        a_document = Document.new
        a_document.add(Field.new('text', id_text_pair[1], Field::Store::YES, Field::Index::NO_NORMS))                       
        #                       Field::Index::TOKENIZED))
        a_document.add(Field.new('id', id_text_pair[0].to_s, Field::Store::YES, Field::Index::TOKENIZED))
        index_writer.updateDocument(term_to_delete, a_document) # delete any old docs with same id
      }
      index_writer.close
    end
  
  
    def find(fields)
      query = BooleanQuery.new
      
      fields.each_pair do |key,value|  
        puts "search '#{key.to_s}' '#{value}'"
        term  = Term.new(key.to_s, value)        
        q = TermQuery.new(term)
        query.add(q, BooleanClause::Occur::MUST)
      end


      engine = IndexSearcher.new(@index_path)
      hits = engine.search(query).iterator
      results = []
      while (hits.hasNext && hit = hits.next)
        id = hit.getDocument.getField("id").stringValue.to_i
        results <<  id #[hit.getScore, id, text]
      end
      engine.close
      results
    end

  
    def delete_documents id_array # e.g., [1,5,88]
      index_available = IndexReader.index_exists(@index_path)
      index_writer = IndexWriter.new(
        @index_path,
        StandardAnalyzer.new,
        !index_available)
      id_array.each {|id|
        index_writer.deleteDocuments(Term.new("id", id.to_s))
      }
      index_writer.close
    end
  end

end
