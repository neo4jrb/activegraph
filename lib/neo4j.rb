require 'neo4j/version'

#require "delegate"
#require "time"
#require "set"
#
#require "active_support/core_ext"
#require "active_support/json"
#require "active_support/inflector"
#require "active_support/time_with_zone"

require "neo4j-core"
require "active_model"
require 'active_support/concern'
require 'active_support/core_ext/class/attribute.rb'

require 'active_attr'
require 'neo4j/wrapper'
require 'neo4j/type_converters'
require "neo4j/active_node/labels"
require 'neo4j/active_node/identity'
require 'neo4j/active_node/callbacks'
require 'neo4j/active_node/initialize'
require 'neo4j/active_node/property'
require 'neo4j/active_node/persistence'
require 'neo4j/active_node/validations'
require 'neo4j/active_node/rels'
require 'neo4j/active_node/has_n'
require 'neo4j/active_node/has_n/decl_rel'
require 'neo4j/active_node/has_n/nodes'
require 'neo4j/active_node'

if defined? Rails::Generators # defined in 'rails/generators.rb'
  # TODO, not sure this is the correct way of adding rails generators
  # See https://github.com/andreasronge/neo4j/blob/gh-pages/neo4j.rb
  # It is required from the rails config/application file
  require 'rails/generators/neo4j_generator'
end
