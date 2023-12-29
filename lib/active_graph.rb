require 'benchmark'
require 'bigdecimal'
require 'bigdecimal/util'
require 'date'
require 'forwardable'
require 'active_model'
require 'active_model/attribute_set'
require 'active_support/core_ext/big_decimal/conversions'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/attribute_accessors_per_thread'
require 'active_support/core_ext/string/conversions'
require 'active_support/inflector'
require 'active_support/inflector/inflections'
require 'active_support/notifications'
require 'json'
require 'neo4j/driver'
require 'orm_adapter'
require 'rake'
require 'set'
require 'sorted_set'
require 'yaml'

loader = Zeitwerk::Loader.for_gem
loader.ignore(File.expand_path('rails', __dir__))
loader.ignore(File.expand_path('active_graph/railtie.rb', __dir__))
loader.inflector.inflect("ansi" => "ANSI")
loader.setup
# loader.eager_load

Neo4j::Driver::Result.prepend ActiveGraph::Core::Result
Neo4j::Driver::Record.prepend ActiveGraph::Core::Record
Neo4j::Driver::Transaction.prepend ActiveGraph::Transaction
Neo4j::Driver::Types::Entity.include ActiveGraph::Core::Wrappable
Neo4j::Driver::Types::Entity.prepend ActiveGraph::Core::Entity
Neo4j::Driver::Types::Node.prepend ActiveGraph::Core::Node
Neo4j::Driver::Types::Node.wrapper_callback(&ActiveGraph::Node::Wrapping.method(:wrapper))
Neo4j::Driver::Types::Relationship.wrapper_callback(&ActiveGraph::Relationship::Wrapping.method(:wrapper))
SecureRandom.singleton_class.prepend ActiveGraph::SecureRandomExt

load 'active_graph/tasks/migration.rake'
