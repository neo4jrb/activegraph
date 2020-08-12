require 'active_graph/core/instrumentable'
require 'active_graph/core/entity'
require 'active_graph/core/node'
require 'active_graph/core/query'
require 'active_graph/core/record'
require 'active_graph/core/wrappable'
require 'active_graph/transaction'
require 'neo4j_ruby_driver'

Neo4j::Driver::Types::Entity.include ActiveGraph::Core::Wrappable
Neo4j::Driver::Types::Entity.prepend ActiveGraph::Core::Entity
Neo4j::Driver::Types::Node.prepend ActiveGraph::Core::Node
Neo4j::Driver::Result.prepend ActiveGraph::Core::Result
Neo4j::Driver::Record.prepend ActiveGraph::Core::Record
