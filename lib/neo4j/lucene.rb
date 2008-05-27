# 
# Stolen code from http://markwatson.com/blog/2007/06/using-lucene-with-jruby.html
#

module Neo4j
  

  class Lucene
  
    # import java classes
    IndexReader = org.apache.lucene.index.IndexReader
    IndexSearcher = org.apache.lucene.search.IndexSearcher
    Term = org.apache.lucene.index.Term
    Document = org.apache.lucene.document.Document
    StandardAnalyzer = org.apache.lucene.analysis.standard.StandardAnalyzer
    Field = org.apache.lucene.document.Field
    TermQuery = org.apache.lucene.search.TermQuery  
    IndexWriter = org.apache.lucene.index.IndexWriter
  
  
    @index_path = nil
    def initialize(an_index_path = "data/")
      @index_path = an_index_path
    end
  
    def index(node)
      index_available = IndexReader.index_exists(@index_path)
      index_writer = IndexWriter.new(@index_path, StandardAnalyzer.new, !index_available)
      
      clazz = node.class
      id    = node.neo_node_id.to_s
      term_to_delete = Term.new("id", id) # if it exists
      doc   = Document.new
      props = node.props
      
      clazz.decl_props.each do |k|
        key = k.to_s
        value = props[key]
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
  
  
    def search(field, value)
      puts "search '#{field}' '#{value}'"
      term  = Term.new(field, value)
      query = TermQuery.new(term)
      engine = IndexSearcher.new(@index_path)
      hits = engine.search(query).iterator
      results = []
      while (hits.hasNext && hit = hits.next)
        id = hit.getDocument.getField("id").stringValue.to_i
        text = hit.getDocument.getField(field).stringValue
        results <<  [hit.getScore, id, text]
      end
      engine.close
      results
    end
  
  
    def search_with_query(query)
      parse_query = org.apache.lucene.queryParser.QueryParser.new(
        'text', StandardAnalyzer.new)
      query = parse_query.parse(query)
      engine = IndexSearcher.new(@index_path)
      hits = engine.search(query).iterator
      results = []
      while (hits.hasNext && hit = hits.next)
        id = hit.getDocument.getField("id").stringValue.to_i
        text = hit.getDocument.getField("text").stringValue
        results << [hit.getScore, id, text]
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


