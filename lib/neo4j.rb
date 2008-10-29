require 'singleton'
require 'thread'
require 'delegate'


require 'neo4j/jars'
require 'neo4j/events'
require 'neo4j/mixins/transactional'
require 'neo4j/mixins/relation'
require 'neo4j/mixins/dynamic_accessor'
require 'neo4j/dynamic_relation'
require 'neo4j/relations'
require 'neo4j/mixins/dynamic_accessor'
require 'neo4j/neo'
require 'neo4j/transaction'
require 'neo4j/relation_info'
require 'neo4j/mixins/node'
require 'neo4j/version'

require 'lucene'
require 'inflector'


# 
# Set logger used by Neo4j
# Need to be done first since loading the required files might use this logger
#
require 'logger'
$NEO_LOGGER = Logger.new(STDOUT)
$NEO_LOGGER.level = Logger::WARN
