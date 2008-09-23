require 'singleton'
require 'thread'
require 'delegate'


require 'neo4j/jars'
require 'neo4j/events'
require 'neo4j/transactional'
require 'neo4j/relations'
require 'neo4j/dynamic_accessor'
require 'neo4j/neo'
require 'neo4j/transaction'
require 'neo4j/index_updater'
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
