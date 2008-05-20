include Java


module Neo
  
  require 'neo-1.0-b6.jar'
  require 'jta-spec1_0_1.jar'
  require 'index-util-0.4-20080512.110337-6.jar'
  require 'lucene-core-2.3.2.jar'

  
  EmbeddedNeo = org.neo4j.api.core.EmbeddedNeo
  Transaction = org.neo4j.api.core.Transaction
  StopEvaluator = org.neo4j.api.core.StopEvaluator
  Traverser = org.neo4j.api.core.Traverser
  ReturnableEvaluator = org.neo4j.api.core.ReturnableEvaluator
  Direction = org.neo4j.api.core.Direction
  IndexService = org.neo4j.util.index.IndexService

  # Need to put these here because of missing constant errors otherwise
  class Node
  end
  
  class MetaNode < Node
  end
  
  class MetaNodes < Node
  end

  
  
  def self.start
    puts "start neo"
    # @@neo = EmbeddedNeo.new("var/neo")  
    Neo::Connection.establish_connection
    
    # add a super node having subnodes to all classnamees
    # a classname is a node that is created for each time someone inherits from the Node class
    transaction do
      # TODO there should only be one metanodes object (@@neo.getReferenceNode)
      @@meta_nodes = MetaNodes.new #(@@neo.getReferenceNode)
    end
    
  end

  def self.meta_nodes
    @@meta_nodes
  end
  
  def self.find_meta_node(classname) 
    meta_nodes.nodes.find{|node| node.meta_classname == classname}    
  end
  
  def self.stop
    puts "stop neo"
    Neo::Connection.instance.disconnect
    # @@neo.shutdown  
  end
  
  def self.transaction      
    tx = Transaction.begin  
    begin  
      yield  
      tx.success  
    rescue Exception => e  
      raise e  
    ensure  
      tx.finish  
    end      
  end  

  def self.create_node
    Neo::Connection.instance.neo.createNode
    # @@neo.createNode
  end

  
  def self.find_node(id) 
    # neo_node = @@neo.findNodeById(id)
    neo_node = Neo::Connection.instance.neo.findNodeById(id)
    load_node(neo_node)
  end
  
  def self.load_node(neo_node)
    classname = neo_node.get_property('classname')
    # get the class that might exist in a module
    clazz = classname.split("::").inject(Kernel) do |container, name|
      container.const_get(name.to_s)
    end
    clazz.new(neo_node)
  end
  
  

  
  require 'singleton'
  require 'connection'
  require 'node'
  require 'relationship_type'
  require 'relations'
  require 'meta_node'
  require 'meta_nodes'
  
  
  
  

  
end


