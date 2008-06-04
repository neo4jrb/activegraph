module Neo4j
    
  
  class LuceneTransaction
    
    # import java classes
    IndexReader = org.apache.lucene.index.IndexReader
    Term = org.apache.lucene.index.Term
    IndexWriter = org.apache.lucene.index.IndexWriter    
    Document = org.apache.lucene.document.Document
    StandardAnalyzer = org.apache.lucene.analysis.standard.StandardAnalyzer
    Field = org.apache.lucene.document.Field

    attr_reader :nodes  # the nodes to be indexed
    
    include javax.transaction.Synchronization
    
    def initialize
      @nodes = {}
    end

    
    #
    # This method is called by the transaction manager after the transaction is 
    # committed or rolled back.
    #
    def afterCompletion(status)
      if status == javax.transaction.Status::STATUS_COMMITTED 
        $NEO_LOGGER.debug{"update lucene index since transaction is commited"}
        @nodes.each_value { |node| update_index(node) } #index(node)}        
      end
      
      $NEO_LOGGER.info{"afterCompletion #{status}"}
    end

    
    def beforeCompletion
      $NEO_LOGGER.info{"beforeCompletion"}
    end
    
    
    #
    # index one node by reading the declared properties
    #
    def update_index(node)
      clazz = node.class
      id    = node.neo_node_id.to_s

      fields = {}
      props = node.props
      
      clazz.decl_props.each do |k|
        key = k.to_s
        fields[key] = props[key]
      end

      begin
        path = node.class.index_storage_path
        update_index_fields(path, id, fields)
      rescue => ex
        # since we will run in a java transaction we will get poor error messages
        # so we log it here instead
        $NEO_LOGGER.error("Can't index node #{node} since #{ex}")        
        ex.backtrace.each{|x| $NEO_LOGGER.error(x)}
      end
      
    end
   
    def update_index_fields(index_path, id, fields)
      index_available = IndexReader.index_exists(index_path)
      index_writer = IndexWriter.new(index_path, StandardAnalyzer.new, !index_available)
      
      term_to_delete = Term.new('id', id) # if it exists
      doc   = Document.new
      doc.add(Field.new('id', id, Field::Store::YES, Field::Index::NO_NORMS))
    
      fields.each_pair do |key, value|  
        doc.add(Field.new(key,value.to_s, Field::Store::YES, Field::Index::NO_NORMS))                               
      end
      
      index_writer.updateDocument(term_to_delete, doc) # delete any old docs with same id
      index_writer.close
    end


# TODO call this when a node is deleted    
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