require 'active_graph/transaction'
require 'active_graph/core/instrumentable'
require 'active_graph/core/query'
require 'active_graph/core/record'

require 'neo4j_ruby_driver'
require 'active_graph/core/wrappable'
require 'active_graph/core/node'
require 'active_graph/core/relationship'

Neo4j::Driver::Types::Entity.include ActiveGraph::Core::Wrappable
Neo4j::Driver::Types::Node.prepend ActiveGraph::Core::Node
Neo4j::Driver::Types::Relationship.include ActiveGraph::Core::Relationship
Neo4j::Driver::StatementResult.prepend ActiveGraph::Core::Result
Neo4j::Driver::Record.prepend ActiveGraph::Core::Record
