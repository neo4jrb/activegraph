require 'neo4j/core/config'

require 'neo4j/transaction'
require 'neo4j/core/query'
require 'neo4j/core/cypher_session/driver'
require 'neo4j/core/cypher_session/responses'

require 'neo4j_ruby_driver'
require 'neo4j/core/wrappable'
require 'neo4j/core/node'
require 'neo4j/core/relationship'

Neo4j::Driver::Types::Entity.include Neo4j::Core::Wrappable
Neo4j::Driver::Types::Node.prepend Neo4j::Core::Node
Neo4j::Driver::Types::Relationship.include Neo4j::Core::Relationship
