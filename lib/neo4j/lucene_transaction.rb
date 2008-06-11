require 'lucene'

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
    # Implement the java callback interface Synchronization
    #
    include javax.transaction.Synchronization
    
    def initialize
      @indexes = {}
    end

    
    #
    # This method is called by the transaction manager after the transaction is 
    # committed or rolled back.
    #
    def afterCompletion(status)
      if status == javax.transaction.Status::STATUS_COMMITTED 
        $NEO_LOGGER.debug{"update lucene index since transaction is commited"}

        # update index of all nodes that has not been deleted
        @indexes.each_value { |index| index.commit } 
      end
      
      $NEO_LOGGER.info{"afterCompletion #{status}"}
    rescue => error 
      # since we will get poor error handling inside a java callback we rescue all exceptions here
      $NEO_LOGGER.error(error)
    end

    
    def beforeCompletion
      $NEO_LOGGER.info{"beforeCompletion"}
    end


    
    def delete_index(node) 
      path = node.class.index_storage_path      
      index(path).delete(node.neo_node_id)
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

    #
    # Make sure that only one index exist per path
    # 
    def index(path)
      @indexes[path] = Lucene::Index.new(path) if @indexes[path].nil?
      @indexes[path]
    end

    def update_index_fields(index_path, id, fields)
      index = index(index_path)
      
      doc = Lucene::Document.new(id)
    
      fields.each_pair do |key, value|  
        doc << Lucene::Field.new(key,value.to_s)
      end

      index.update(doc)
    end


  end
end