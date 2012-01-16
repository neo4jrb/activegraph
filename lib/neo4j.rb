require 'enumerator'
require 'forwardable'
require 'time'
require 'date'
require 'tmpdir'

# Rails
require 'rails/railtie'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_model'

# core extensions
require 'neo4j/core_ext/class/inheritable_attributes'


module Neo4j
  include Java

  # Enumerator has been moved to top level in Ruby 1.9.2, make it compatible with Ruby 1.8.7
  Enumerator = Enumerable::Enumerator unless defined? Enumerator
end

require 'neo4j-community'
require 'neo4j/version'
require 'neo4j/neo4j'
require 'neo4j/paginated'
require 'neo4j/node'
require 'neo4j/relationship'
require 'neo4j/relationship_set'
require 'neo4j/type_converters/type_converters'
require 'neo4j/index/index'
require 'neo4j/traversal/traversal'
require 'neo4j/property/property'
require 'neo4j/has_n/has_n'
require 'neo4j/node_mixin/node_mixin'
require 'neo4j/relationship_mixin/relationship_mixin'
require 'neo4j/rule/rule'
require 'neo4j/rels/rels'
require 'neo4j/rails/rails'
require 'neo4j/model'
require 'neo4j/migrations/migrations'
require 'neo4j/algo/algo'
require 'neo4j/batch/batch'
require 'orm_adapter/adapters/neo4j'
require 'neo4j/identity_map'


Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].each { |ext| load ext } if defined?(Rake) && respond_to?(:namespace)
