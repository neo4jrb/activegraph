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
    # ref_node : the reference, ReferenceNode, node, wraps a org.neo4j.api.core.NeoService#getReferenceNode
    #
    attr_reader :ref_node


    #
    # Holds references to all other nodes
    # The classname of the nodes are used as the name of the relationship to those nodes.
    # There is only one reference node in a neo space, which can always been found (Neo4j::Neo#:ref_node)
    #
    class ReferenceNode
      include Neo4j::NodeMixin
      include Neo4j::DynamicAccessorMixin

      has_n :roots

      def initialize(*args)
        super
        set_property('classname', self.class.to_s) if property?('classname').nil?
      end

      #
      # Connects the given node with the reference node
      #
      def connect(node)
        clazz = node.class.root_class
        type = Neo4j::Relations::RelationshipType.instance(clazz)
        internal_node.createRelationshipTo(node.internal_node, type) #if Transaction.running?
      end
    end
    
    #
    # starts neo with a database at the given storage location
    # 
    def start(storage = NEO_STORAGE)
      @db_storage = storage
      
      raise Exception.new("Already started neo") if @neo
      @neo = org.neo4j.api.core.EmbeddedNeo.new(@db_storage)
      Transaction.run { @ref_node = ReferenceNode.new(@neo.getReferenceNode()) }
      $NEO_LOGGER.info{ "Started neo. Database storage located at '#{@db_storage}'"}
    end
    
    
    #
    # Create an internal neo node (returns a java object)
    # Don't use this method - only for internal use.
    #
    def create_node
      @neo.createNode
    end

    #
    # Returns an internal neo transaction object.
    # Don't use this method - only for internal use.
    #
    def begin_transaction
      @neo.begin_tx
    end

    
    #
    # Returns a NodeMixin object that has the given id or nil if it does not exist.
    # 
    def find_node(id) 
      begin
        neo_node = @neo.getNodeById(id)
        load_node(neo_node)
      rescue org.neo4j.api.core.NotFoundException 
        nil
      end
    end
  


    #
    # Loads a Neo node
    # Expects the neo property 'classname' to exist.
    # That property is used to load the ruby instance
    #
    def load_node(neo_node)
      return nil unless neo_node.has_property('classname')
      _load neo_node.get_property('classname'), neo_node
    end


    #
    # Loads a Neo relationship
    # If the neo property 'classname' to exist it will use that to create an instance of that class.
    # Otherwise it will create an instance of Neo4j::Relations::DynamicRelation that represent 'rel'
    #
    def load_relationship(rel)
      classname = rel.get_property('classname') if rel.has_property('classname')
      classname = Neo4j::Relations::DynamicRelation.to_s if classname.nil?
      _load classname, rel
    end

    def _load(classname, node_or_relationship)
      clazz = classname.split("::").inject(Kernel) do |container, name|
        container.const_get(name.to_s)
      end
      clazz.new(node_or_relationship)
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

