require 'neo/java_libs'
require 'neo/neo_service'
require 'neo/node'

module Neo
  

  #
  # Runs a block in a Neo transaction
  #
  # All CRUD operations must be run in a transaction
  # If a block is given then that block will be executed in a transaction, 
  # otherwise it will simply return a java neo transaction object.
  #
  def transaction     
    return Transaction unless block_given?

    tx = Transaction.begin  
    
    begin  
      yield tx
      tx.success  
    rescue Exception => e  
      raise e  
    ensure  
      tx.finish  
    end      
  end  

  #
  # Returns a NeoService
  # 
  def neo_service
    NeoService.instance
  end  
  
  module_function :transaction, :neo_service
end

