module Neo4j
  
  
  #
  # Default location of neo storage
  NEO_STORAGE = 'var/neo'
    
  #
  # Default location of lucene index files
  #
  LUCENE_INDEX_STORAGE = 'var/lucene'
  
  #
  # Allows run and stop the Neo4j service
  # Contains global ćonstants such as location of the neo storage and index files
  # on the filesystem.
  # 
  # A wrapper class around org.neo4j.api.core.EmbeddedNeo
  # 
  class Neo
    include Singleton
    attr_accessor :db_storage

    #
    # meta_nodes : Return the meta nodes containing relationship to all MetaNode objects
    #
    attr_reader :meta_nodes 
    
    
    
    #
    # starts neo with a database at the given storage location
    # 
    def start(storage = NEO_STORAGE)
      @db_storage = storage
      
      raise Exception.new("Already started neo") if @neo
      @neo = EmbeddedNeo.new(@db_storage)  
      $NEO_LOGGER.info{ "Started neo. Database storage located at '#{@db_storage}'"}
    end
    
    
    #
    # Create an internal neo node (returns a java object)
    #
    def create_node
      @neo.createNode
    end
    
    
    def index_node(node)
      raise NotInTransactionError.new unless Transaction.running?
      Transaction.current.index_node node
    end
    
    
    #
    # Returns a Node object that has the given id or nil if it does not exist.
    # 
    def find_node(id) 
      begin
        neo_node = @neo.getNodeById(id)
        load_node(neo_node)
      rescue org.neo4j.impl.core.NotFoundException
        nil
      end
    end
  

        
    def load_node(neo_node)
      classname = neo_node.get_property('classname')
      
      # find the class (classes are constants) 
      clazz = classname.split("::").inject(Kernel) do |container, name|
        container.const_get(name.to_s)
      end
      clazz.new(neo_node)
    end
    
    alias :load_relationship :load_node
    
    #
    # Stop neo
    # Must be done before the program stops
    #
    def stop
      $NEO_LOGGER.info {"stop neo #{@neo}"}
      @neo.shutdown  
      @neo = nil
    end


    
    def tx_manager
      @neo.getConfig().getTxModule().getTxManager()
    end
    
    
  end
end

