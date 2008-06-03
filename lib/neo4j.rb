require 'neo4j/jars'
require 'neo4j/neo'
require 'neo4j/transaction'
require 'neo4j/lucene'
require 'neo4j/node'


# 
# Set logger used by Neo4j
# Need to be done first since loading the required files might use this logger
#
require 'logger'
$NEO_LOGGER = Logger.new(STDOUT)
$NEO_LOGGER.level = Logger::WARN
#$NEO_LOGGER.level = Logger::DEBUG
