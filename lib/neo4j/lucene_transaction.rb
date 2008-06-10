require 'neo4j/jars'

module Neo4j
    
  class LuceneIndexOutOfSyncException < RuntimeError
  end
  
  class LuceneTransaction
    
    # import java classes
    IndexReader = org.apache.lucene.index.IndexReader
    Term = org.apache.lucene.index.Term
    IndexWriter = org.apache.lucene.index.IndexWriter    
    Document = org.apache.lucene.document.Document
    StandardAnalyzer = org.apache.lucene.analysis.standard.StandardAnalyzer
    Field = org.apache.lucene.document.Field

    
    #
    # Must store which nodes should be indexed and deleted since we will
    # update the index first after the transaction is commited.
    #
    attr_reader :nodes  # a hash of id and nodes that should be indexed
    attr_reader :deleted_nodes # a hash of id and nodes that should be deleted from index
    
    #
    # Implement the java callback interface Synchronization
    #
    include javax.transaction.Synchronization
    
    def initialize
      @nodes = {}
      @deleted_nodes = {}
    end

    
    #
    # This method is called by the transaction manager after the transaction is 
    # committed or rolled back.
    #
    def afterCompletion(status)
      if status == javax.transaction.Status::STATUS_COMMITTED 
        $NEO_LOGGER.debug{"update lucene index since transaction is commited"}

        # delete documents for nodes that has been deleted
        @deleted_nodes.each_value {|node| delete_document(node.class.index_storage_path, node.neo_node_id)}
        
        # make sure we do not update nodes that has been deleted
        deleted_ids = @nodes.keys & @deleted_nodes.keys
        deleted_ids.each {|id| @nodes.delete(id)}
        $NEO_LOGGER.debug("delet from updated: #{deleted_ids}")        
        
        # update index of all nodes that has not been deleted
        @nodes.each_value { |node| update_index(node) } 
      end
      
      $NEO_LOGGER.info{"afterCompletion #{status}"}
    rescue => error 
      # since we will get poor error handling inside a java callback we rescue all exceptions here
      $NEO_LOGGER.error(error)
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

      path = node.class.index_storage_path
      update_index_fields(path, id, fields)
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


    def delete_document(index_path, id) # e.g., [1,5,88]
      index_available = IndexReader.index_exists(index_path)
      index_writer = IndexWriter.new(
        index_path,
        StandardAnalyzer.new,
        !index_available)
      index_writer.deleteDocuments(Term.new("id", id.to_s))
      index_writer.close
    end
  end
end