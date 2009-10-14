# external dependencies
require 'singleton'
require 'thread'
require 'delegate'

# external jars
require 'neo4j/jars'

# lucene
require 'lucene'

# config
require 'neo4j/config'

# mixins
require 'neo4j/mixins/transactional_mixin'
require 'neo4j/mixins/relationship_mixin'
require 'neo4j/mixins/node_mixin'

# relationships
require 'neo4j/relationships/relationship_info'
require 'neo4j/relationships/relationship'
require 'neo4j/relationships/wrappers'
require 'neo4j/relationships/traversal_position'
require 'neo4j/relationships/has_n'
require 'neo4j/relationships/relationship_traverser'
require 'neo4j/relationships/node_traverser'
require 'neo4j/relationships/has_list'

# neo4j
require 'neo4j/indexer' # this will replace neo4j/events
require 'neo4j/neo'
require 'neo4j/event_handler'
require 'neo4j/reference_node'
require 'neo4j/transaction'
require 'neo4j/search_result'
require 'neo4j/node'
# require 'neo4j/tx_node_list'   - has to be included if we want this feature
require 'neo4j/version'



# 
# Set logger used by Neo4j
# Need to be done first since loading the required files might use this logger
#
require 'logger'
$NEO_LOGGER = Logger.new(STDOUT)  # todo use a better logger
$NEO_LOGGER.level = Logger::WARN
