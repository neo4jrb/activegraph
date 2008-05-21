require 'neo/java_libs'
require 'neo/neo_service'
require 'neo/node'
require 'logger'

module Neo
 
  # 
  # Set logger used by Neo
  $neo_logger = Logger.new(STDOUT)
  $neo_logger.level = Logger::WARN
 
  
  #
  # Runs a block in a Neo transaction
  #
  #  Most operations on neo requires an transaction.
  #  include 'neo'
  #
  #  Neo::transaction {
  #    node = Neo.new
  #  }
  #
  # You have also access to transaction object
  #
  #   Neo::transaction { |t|
  #     # something failed
  #     t.failure # will cause a rollback
  #   }
  #
  #
  # If a block is not given than the transaction method will return a transaction object.
  #
  #   transaction = Neo::transaction
  #   transaction.begin
  # etc ...
  # 
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

