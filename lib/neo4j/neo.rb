require 'singleton'

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
    attr_accessor :db_storage, :index_storage 

    #
    # meta_nodes : Return the meta nodes containing relationship to all MetaNode objects
    #
    attr_reader :meta_nodes 
    
    
    
    #
    # starts neo with a database at the given storage location
    # 
    def start(storage = NEO_STORAGE, index_storage = LUCENE_INDEX_STORAGE)
      @db_storage = storage
      @index_storage = index_storage
      
      raise Exception.new("Already started neo") if @neo
      @neo = EmbeddedNeo.new(@db_storage)  
      
      ref_node = nil
      Neo4j::Transaction.run do
        ref_node = @neo.getReferenceNode
        @meta_nodes = MetaNodes.new(ref_node)
      end
      
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
    # Find the meta node represented by the given Ruby class name
    #
    def find_meta_node(classname) 
      @meta_nodes.nodes.find{|node| node.ref_classname == classname}    
    end
    
    #
    # Returns a Node object that has the given id or nil
    # 
    def find_node(id) 
      neo_node = @neo.getNodeById(id)
      load_node(neo_node)
    end
  
    
    def load_node(neo_node)
      classname = neo_node.get_property('classname')
      
      # find the class (classes are constants) 
      clazz = classname.split("::").inject(Kernel) do |container, name|
        container.const_get(name.to_s)
      end
      clazz.new(neo_node)
    end
    
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

