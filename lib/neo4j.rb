require 'neo4j/java_libs'
require 'neo4j/neo'
require 'neo4j/transaction'
require 'neo4j/lucene'
require 'neo4j/node'


# 
# Set logger used by Neo4j
# Need to be done first since loading the required files might use this logger
#
require 'logger'
$neo_logger = Logger.new(STDOUT)
$neo_logger.level = Logger::WARN
#$neo_logger.level = Logger::DEBUG
