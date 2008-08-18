require 'neo4j/jars'
require 'neo4j/neo'
require 'neo4j/transaction'
require 'neo4j/node'
require 'lucene'
require 'inflector'

# 
# Set logger used by Neo4j
# Need to be done first since loading the required files might use this logger
#
require 'logger'
$NEO_LOGGER = Logger.new(STDOUT)
$NEO_LOGGER.level = Logger::WARN
#$NEO_LOGGER.level = Logger::INFO
#$NEO_LOGGER.level = Logger::DEBUG

#Neo4j::Neo.instance.start
#  
#module Baaz
#  class Customer
#    include Neo4j::Node
#    relations :purchases
#  end
#       
#  class Purchase
#    include Neo4j::Node
#  end
#  class CustomerPurchaseRelation
#    include Neo4j::Relation
#  end
#end
#
#c = Baaz::Customer.new
#c.name = 'kalle'
#p = Baaz::Purchase.new
#Neo4j::Transaction.run do
#  c.purchases << p
#  p.customer.nodes.each {|n| puts "Customer #{n.name}"}
#end
#Neo4j::Neo.instance.stop    